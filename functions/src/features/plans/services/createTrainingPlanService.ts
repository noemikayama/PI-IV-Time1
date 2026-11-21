// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: concludePlan substituído por closePlan.
// Alteração: Planejamento, cópia da avaliação e conclusão do plano vencido
// compartilhados com a edição.
// Alteração: Cópia do treinamento montada pela feature de treinamentos.
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cadastro do plano de treinamento já ATIVO, com a geração dos
// registros de treino e a conclusão do plano vencido do cavalo.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import type {ClientSession} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {isDuplicateKeyError} from "../../../shared/errors/isDuplicateKeyError";
import {getTodayYmd, toYmd} from "../../../shared/utils/dates";
import {findHorseEvaluation} from "../../evaluations";
import type {EvaluationDocument} from "../../evaluations";
import {
  assertActiveAccount,
  loadHorseAccess,
  updateHorseDocument,
} from "../../horses";
import {
  closePlannedRecords,
  ensureTrainingRecordIndexes,
  findTrainerTrainings,
  insertTrainingRecords,
  toTrainingSnapshot,
} from "../../training";
import type {TrainingDocument} from "../../training";
import {
  closePlan,
  ensurePlanIndexes,
  findActivePlan,
  insertPlan,
  nextPlanCode,
} from "../repositories/planRepository";
import type {
  PlanDocument,
  PlanEvaluationCopy,
  PlanningItem,
  TrainingPlanInput,
  TrainingPlanResult,
  TrainingsByDay,
} from "../types";
import {splitByHorse} from "./listTrainingGalleryService";
import {
  buildTrainingRecords,
  groupDaysByTraining,
  listPlannedDates,
} from "./planSchedule";

export const ACTIVE_PLAN_MESSAGE = "Este cavalo já tem um plano ativo.";

export const NO_PLANNED_DATES_MESSAGE =
  "Nenhum dia do período escolhido tem treino. Ajuste as datas ou os " +
  "dias da semana.";

export const toDate = (ymd: string): Date => new Date(`${ymd}T00:00:00.000Z`);

/** Copia a avaliação que originou o plano (DD 2.7), com o _id da original.
 * @param {EvaluationDocument} evaluation Avaliação de origem.
 * @return {PlanEvaluationCopy} Cópia guardada no plano.
 */
export const toEvaluationCopy = (
  evaluation: EvaluationDocument
): PlanEvaluationCopy => ({
  _id: evaluation._id,
  codigo: evaluation.codigo,
  data: evaluation.data,
  condicionamentoFisicoObservado: evaluation.condicionamentoFisicoObservado,
  ...(evaluation.limitacoes && {limitacoes: evaluation.limitacoes}),
  ...(evaluation.dificuldades && {dificuldades: evaluation.dificuldades}),
  modalidades: evaluation.modalidades,
  observacoes: evaluation.observacoes,
});

/** Monta o planejamento a partir do treino de cada dia: um item por
 * treinamento. No cadastro ('current' vazio), os códigos são 1, 2, 3... Na
 * edição, o treinamento que continua no plano mantém o item e a cópia (só os
 * dias mudam), os novos recebem os códigos seguintes e os que saíram ficam
 * com o item desativado. Os treinamentos novos precisam ser do treinador, e
 * nenhum treinamento do plano pode usar exercício específico de outro cavalo.
 * @param {string} uid UID do treinador.
 * @param {TrainingsByDay} byDay Treino escolhido em cada dia.
 * @param {ObjectId} horseId _id do cavalo do plano.
 * @param {PlanningItem[]} current Planejamento atual (edição).
 * @return {Promise<PlanningItem[]>} Itens do planejamento.
 */
export async function buildPlanning(
  uid: string,
  byDay: TrainingsByDay,
  horseId: ObjectId,
  current: PlanningItem[] = []
): Promise<PlanningItem[]> {
  const groups = groupDaysByTraining(byDay);
  const kept = new Map(
    current
      .filter((item) => item.ativo)
      .map((item) => [item.treinamento._id.toHexString(), item])
  );
  const newIds = groups
    .map((group) => group.treinamentoId)
    .filter((id) => !kept.has(id.toHexString()));
  const trainings = newIds.length === 0 ?
    [] :
    await findTrainerTrainings(uid, newIds);
  const byId = new Map(trainings.map((training) => [
    training._id.toHexString(),
    training,
  ]));

  // Não diferencia treinamento inexistente de treinamento de outro
  // treinador, para não revelar o acervo alheio.
  if (byId.size !== newIds.length) {
    throw new AppError(
      "not-found",
      "Treinamento não encontrado entre os seus."
    );
  }

  const snapshots = groups.map((group) => {
    const hex = group.treinamentoId.toHexString();
    return kept.get(hex)?.treinamento ??
      toTrainingSnapshot(byId.get(hex) as TrainingDocument);
  });
  const {blocked} = await splitByHorse(snapshots, horseId);
  if (blocked.length > 0) {
    const titles = blocked.map((training) => `"${training.titulo}"`);
    throw new AppError(
      "invalid-argument",
      `O treino ${titles.join(", ")} usa exercício específico de outro ` +
        "cavalo e não pode entrar neste plano."
    );
  }

  let nextCode = Math.max(0, ...current.map((item) => item.codigo)) + 1;
  const active = groups.map((group, index): PlanningItem => {
    const item = kept.get(group.treinamentoId.toHexString());
    return item ?
      {...item, diasSemana: group.diasSemana} :
      {
        codigo: nextCode++,
        ativo: true,
        diasSemana: group.diasSemana,
        treinamento: snapshots[index],
      };
  });
  const used = new Set(active.map((item) => item.codigo));
  const inactive = current
    .filter((item) => !used.has(item.codigo))
    .map((item) => ({...item, ativo: false}));
  return [...active, ...inactive];
}

/** Conclui o plano ATIVO do cavalo que já venceu (dataFim antes de hoje):
 * CONCLUIDO, e os registros PLANEJADO viram NAO_REALIZADO. Um plano ATIVO
 * ainda em andamento impede o cadastro. O planoAtual do cavalo é
 * substituído pelo do plano novo, na mesma transação.
 * @param {ObjectId} horseId _id do cavalo.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<void>} Resolvida quando não houver plano ATIVO.
 */
export async function closeExpiredPlan(
  horseId: ObjectId,
  session: ClientSession
): Promise<void> {
  const active = await findActivePlan(horseId, session);
  if (!active) return;

  const dataFim = toYmd(active.dataFim);
  if (dataFim >= getTodayYmd()) {
    const [year, month, day] = dataFim.split("-");
    throw new AppError(
      "failed-precondition",
      `${ACTIVE_PLAN_MESSAGE} Ele termina em ${day}/${month}/${year}.`
    );
  }
  await closePlan(active._id, "CONCLUIDO", session);
  await closePlannedRecords(active._id, session);
}

/** Converte o plano no formato do app (o callable não converte ObjectId
 * nem Date).
 * @param {PlanDocument} plan Plano gravado.
 * @param {number} records Quantidade de registros gerados.
 * @return {TrainingPlanResult} Resposta do cadastro.
 */
const toResult = (
  plan: PlanDocument,
  records: number
): TrainingPlanResult => ({
  plano: {
    id: plan._id.toHexString(),
    codigo: plan.codigo,
    status: plan.status,
    dataInicio: toYmd(plan.dataInicio),
    dataFim: toYmd(plan.dataFim),
    planejamento: plan.planejamento.map((item) => {
      const {_id, exercicios, ...treinamento} = item.treinamento;
      return {
        codigo: item.codigo,
        diasSemana: item.diasSemana,
        treinamento: {
          id: _id.toHexString(),
          ...treinamento,
          exercicios: exercicios.map(({_id: exerciseId, ...exercise}) => ({
            id: exerciseId.toHexString(),
            ...exercise,
          })),
        },
      };
    }),
  },
  registrosGerados: records,
});

/** Cadastra o plano do cavalo já como ATIVO (RASCUNHO não é usado neste
 * fluxo). Plano, registros PLANEJADO, planoAtual do cavalo e conclusão do
 * plano vencido são gravados em uma transação.
 * @param {string} uid UID do treinador autenticado.
 * @param {TrainingPlanInput} input Dados validados do cadastro.
 * @return {Promise<TrainingPlanResult>} Plano criado e registros gerados.
 */
export async function createTrainingPlanService(
  uid: string,
  input: TrainingPlanInput
): Promise<TrainingPlanResult> {
  const [trainer, planejamento] = await Promise.all([
    assertActiveAccount(uid, ROLES.trainer),
    buildPlanning(uid, input.treinosPorDia, input.cavaloId),
    ensurePlanIndexes(),
    ensureTrainingRecordIndexes(),
  ]);

  const dataInicio = toDate(input.dataInicio);
  const dataFim = toDate(input.dataFim);
  if (listPlannedDates({dataInicio, dataFim, planejamento}).length === 0) {
    throw new AppError("invalid-argument", NO_PLANNED_DATES_MESSAGE);
  }

  try {
    return await runInTransaction(async (session) => {
      // Cavalo inativo ou sem vínculo com o treinador: 'not-found'.
      const {horse} = await loadHorseAccess(
        input.cavaloId,
        uid,
        undefined,
        session
      );
      const evaluation = input.avaliacaoId ?
        await findHorseEvaluation(input.avaliacaoId, horse._id, session) :
        null;
      if (input.avaliacaoId && !evaluation) {
        throw new AppError(
          "not-found",
          "Avaliação não encontrada para este cavalo."
        );
      }

      await closeExpiredPlan(horse._id, session);

      const now = new Date();
      const plan: PlanDocument = {
        _id: new ObjectId(),
        codigo: await nextPlanCode(session),
        titulo: input.titulo,
        objetivo: input.objetivo,
        cavalo: {_id: horse._id, codigo: horse.codigo, nome: horse.nome},
        treinador: {_id: uid, codigo: trainer.codigo, nome: trainer.nome},
        ...(evaluation && {avaliacaoInicial: toEvaluationCopy(evaluation)}),
        status: "ATIVO",
        dataInicio,
        dataFim,
        planejamento,
        criadoEm: now,
        atualizadoEm: now,
      };

      // O atleta atual vai como responsável; sem atleta, o campo é
      // omitido e a agenda continua achando o registro pelo cavalo.
      const {atleta} = horse;
      const records = buildTrainingRecords(
        {
          ...plan,
          ...(atleta && {
            responsavel: {
              _id: atleta._id,
              codigo: atleta.codigo,
              nome: atleta.nome,
            },
          }),
        },
        now
      );

      await insertPlan(plan, session);
      await insertTrainingRecords(records, session);
      await updateHorseDocument(
        horse._id,
        {
          $set: {
            planoAtual: {
              _id: plan._id,
              codigo: plan.codigo,
              titulo: plan.titulo,
              dataInicio: input.dataInicio,
              dataFim: input.dataFim,
            },
            atualizadoEm: now,
          },
        },
        session
      );

      return toResult(plan, records.length);
    });
  } catch (error) {
    // Outro plano ativado ao mesmo tempo. Só esse índice vira a mensagem
    // de plano ativo; outra chave duplicada segue como erro interno.
    if (
      isDuplicateKeyError(error) &&
      (error as Error).message.includes("idx_planos_cavalo_ativo")
    ) {
      throw new AppError("failed-precondition", ACTIVE_PLAN_MESSAGE);
    }
    throw error;
  }
}
