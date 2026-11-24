// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Edição do plano de treinamento.
// Alteração: Resposta montada com os registros já atualizados.
// -----------------------------------------------------------------------------

import type {ClientSession, ObjectId} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {isDuplicateKeyError} from "../../../shared/errors/isDuplicateKeyError";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import {getDayStart, toYmd} from "../../../shared/utils/dates";
import {findHorseEvaluation} from "../../evaluations";
import {
  assertActiveAccount,
  loadHorseAccess,
  updateHorseDocument,
} from "../../horses";
import type {HorseDocument} from "../../horses";
import {
  applyPlanRecordChanges,
  ensureTrainingRecordIndexes,
  findPlanRecordsFrom,
  insertTrainingRecords,
} from "../../training";
import type {
  NewTrainingRecord,
  PlanRecordState,
} from "../../training";
import {
  ensurePlanIndexes,
  findPlanById,
  updatePlanContent,
} from "../repositories/planRepository";
import type {
  PlanContent,
  PlanDocument,
  PlanEvaluationCopy,
  PlanStatus,
  TrainingPlanDetailsResult,
  TrainingPlanUpdateInput,
} from "../types";
import {START_IN_PAST_MESSAGE} from "../validations/validateTrainingPlan";
import {
  ACTIVE_PLAN_MESSAGE,
  buildPlanning,
  closeExpiredPlan,
  NO_PLANNED_DATES_MESSAGE,
  toDate,
  toEvaluationCopy,
} from "./createTrainingPlanService";
import {loadTrainingPlanDetails} from "./getTrainingPlanDetailsService";
import {
  displayedStatus,
  PLAN_NOT_FOUND_MESSAGE,
  planPermissions,
  resolvePlanViewer,
} from "./planAccess";
import {buildTrainingRecords, listPlannedDates} from "./planSchedule";

// Por que o plano não pode ser editado, pelo status exibido.
const NOT_EDITABLE: Record<"CONCLUIDO" | "CANCELADO", string> = {
  CONCLUIDO: "Este plano já terminou e não pode ser editado.",
  CANCELADO: "Este plano foi cancelado e não pode ser editado.",
};

// Mudanças nos registros já gravados e registros novos.
export type RecordPlan = {
    refresh: {id: ObjectId; record: NewTrainingRecord}[];
    cancel: ObjectId[];
    insert: NewTrainingRecord[];
};

/** Confere as datas e o cavalo contra o andamento do plano. Depois que o
 * plano começou, a data de início e o cavalo não mudam (o histórico já
 * está no cavalo). Antes disso, o início precisa ser hoje ou depois. O fim
 * nunca fica antes de hoje.
 * @param {PlanDocument} plan Plano atual.
 * @param {TrainingPlanUpdateInput} input Estado final da tela.
 * @param {Date} today Hoje (meia-noite UTC).
 */
export function assertEditablePeriod(
  plan: Pick<PlanDocument, "dataInicio" | "cavalo">,
  input: Pick<TrainingPlanUpdateInput, "dataInicio" | "dataFim" | "cavaloId">,
  today: Date
): void {
  const todayYmd = toYmd(today);
  if (plan.dataInicio <= today) {
    if (input.dataInicio !== toYmd(plan.dataInicio)) {
      throw new AppError(
        "failed-precondition",
        "A data de início não pode mudar depois que o plano começou."
      );
    }
    if (!input.cavaloId.equals(plan.cavalo._id)) {
      throw new AppError(
        "failed-precondition",
        "O cavalo não pode mudar depois que o plano começou."
      );
    }
  } else if (input.dataInicio < todayYmd) {
    throw new AppError("invalid-argument", START_IN_PAST_MESSAGE);
  }
  if (input.dataFim < todayYmd) {
    throw new AppError(
      "invalid-argument",
      "A data de fim não pode ser anterior a hoje."
    );
  }
}

/** Decide o que fazer com os registros de hoje em diante (sem banco). O
 * registro já começado ou executado fica como está e ocupa o dia: nenhum
 * outro é gerado nessa data. Os demais seguem o plano editado: o que
 * continua (mesmo item e data) é renovado, o que saiu é cancelado (nunca
 * removido, DD 5.2) e o que entrou é gerado.
 * @param {NewTrainingRecord[]} desired Registros do plano editado.
 * @param {PlanRecordState[]} existing Registros gravados de hoje em diante.
 * @return {RecordPlan} O que renovar, cancelar e inserir.
 */
export function planRecordChanges(
  desired: NewTrainingRecord[],
  existing: PlanRecordState[]
): RecordPlan {
  const key = (item: number, date: Date) => `${item}|${date.getTime()}`;
  const untouched = (record: PlanRecordState) =>
    (record.status === "PLANEJADO" || record.status === "CANCELADO") &&
    record.exercicios.every((exercise) => exercise.realizacao === "PENDENTE");

  const byKey = new Map(existing.map((record) => [
    key(record.itemPlanejamento, record.dataPlanejada),
    record,
  ]));
  const lockedDays = new Set(
    existing
      .filter((record) => !untouched(record))
      .map((record) => record.dataPlanejada.getTime())
  );

  const result: RecordPlan = {refresh: [], cancel: [], insert: []};
  const keptKeys = new Set<string>();
  for (const record of desired) {
    if (lockedDays.has(record.dataPlanejada.getTime())) continue;
    const recordKey = key(record.itemPlanejamento, record.dataPlanejada);
    keptKeys.add(recordKey);
    const current = byKey.get(recordKey);
    if (current) result.refresh.push({id: current._id, record});
    else result.insert.push(record);
  }
  result.cancel = existing
    .filter((record) =>
      record.status === "PLANEJADO" &&
      untouched(record) &&
      !keptKeys.has(key(record.itemPlanejamento, record.dataPlanejada))
    )
    .map((record) => record._id);
  return result;
}

/** Cópia da avaliação escolhida. A atual é mantida sem nova leitura quando
 * o cavalo não muda; outra precisa ser do cavalo do plano.
 * @param {PlanDocument} plan Plano atual.
 * @param {ObjectId|null} evaluationId Avaliação escolhida, ou null.
 * @param {ObjectId} horseId Cavalo do plano editado.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<PlanEvaluationCopy|undefined>} Cópia, ou nenhuma.
 */
async function resolveEvaluation(
  plan: PlanDocument,
  evaluationId: ObjectId | null,
  horseId: ObjectId,
  session: ClientSession
): Promise<PlanEvaluationCopy | undefined> {
  if (!evaluationId) return undefined;
  const current = plan.avaliacaoInicial;
  if (
    current &&
    current._id.equals(evaluationId) &&
    plan.cavalo._id.equals(horseId)
  ) {
    return current;
  }
  const evaluation = await findHorseEvaluation(evaluationId, horseId, session);
  if (!evaluation) {
    throw new AppError(
      "not-found",
      "Avaliação não encontrada para este cavalo."
    );
  }
  return toEvaluationCopy(evaluation);
}

/** Leva o plano ATIVO editado para os registros de hoje em diante e para
 * o planoAtual do cavalo (do antigo para o novo, se o cavalo mudou).
 * @param {PlanDocument} plan Plano já editado.
 * @param {ObjectId} previousHorseId Cavalo antes da edição.
 * @param {HorseDocument} horse Cavalo do plano editado.
 * @param {Date} today Hoje (meia-noite UTC).
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<void>} Resolvida quando tudo for gravado.
 */
async function syncActivePlan(
  plan: PlanDocument,
  previousHorseId: ObjectId,
  horse: HorseDocument,
  today: Date,
  session: ClientSession
): Promise<void> {
  // O atleta atual vai como responsável, como no cadastro.
  const {atleta} = horse;
  const desired = buildTrainingRecords(
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
    plan.atualizadoEm,
    today
  );
  const changes = planRecordChanges(
    desired,
    await findPlanRecordsFrom(plan._id, today, session)
  );
  await applyPlanRecordChanges(
    plan._id,
    {titulo: plan.titulo, refresh: changes.refresh, cancel: changes.cancel},
    session
  );
  await insertTrainingRecords(changes.insert, session);

  if (!previousHorseId.equals(horse._id)) {
    await updateHorseDocument(
      previousHorseId,
      {$unset: {planoAtual: ""}, $set: {atualizadoEm: plan.atualizadoEm}},
      session
    );
  }
  await updateHorseDocument(
    horse._id,
    {
      $set: {
        planoAtual: {
          _id: plan._id,
          codigo: plan.codigo,
          titulo: plan.titulo,
          dataInicio: toYmd(plan.dataInicio),
          dataFim: toYmd(plan.dataFim),
        },
        atualizadoEm: plan.atualizadoEm,
      },
    },
    session
  );
}

/** Edita o plano com o estado final da tela, em uma transação. Só o
 * treinador que vê o botão (autor do plano ou treinador atual do cavalo)
 * edita, e só planos RASCUNHO ou ATIVO ainda não vencidos. A edição vale
 * de hoje em diante: o que já passou ou foi executado não muda. Devolve a
 * tela do plano editado, como a visualização.
 * @param {AuthenticatedUser} user Treinador autenticado.
 * @param {TrainingPlanUpdateInput} input Estado final da tela.
 * @param {Date} now Momento da edição.
 * @return {Promise<TrainingPlanDetailsResult>} Plano editado.
 */
export async function updateTrainingPlanService(
  user: AuthenticatedUser,
  input: TrainingPlanUpdateInput,
  now = new Date()
): Promise<TrainingPlanDetailsResult> {
  await Promise.all([
    assertActiveAccount(user.uid, ROLES.trainer),
    ensurePlanIndexes(),
    ensureTrainingRecordIndexes(),
  ]);
  const today = getDayStart(now);

  try {
    return await runInTransaction(async (session) => {
      const plan = await findPlanById(input.planoId, session);
      if (!plan) throw new AppError("not-found", PLAN_NOT_FOUND_MESSAGE);

      const viewer = await resolvePlanViewer(user, plan, session);
      const status: PlanStatus = displayedStatus(plan, today);
      if (!planPermissions(viewer.role, status).podeEditar) {
        throw new AppError(
          "failed-precondition",
          NOT_EDITABLE[status as keyof typeof NOT_EDITABLE]
        );
      }
      assertEditablePeriod(plan, input, today);

      // Cavalo inativo ou sem vínculo com o treinador: 'not-found'.
      const {horse} = await loadHorseAccess(
        input.cavaloId,
        user.uid,
        undefined,
        session
      );
      const horseChanged = !horse._id.equals(plan.cavalo._id);
      // Como no cadastro: conclui o plano vencido do cavalo novo e recusa
      // se ele tiver outro em andamento.
      if (horseChanged && plan.status === "ATIVO") {
        await closeExpiredPlan(horse._id, session);
      }

      const avaliacaoInicial = await resolveEvaluation(
        plan,
        input.avaliacaoId,
        horse._id,
        session
      );
      const content: PlanContent = {
        titulo: input.titulo,
        objetivo: input.objetivo,
        cavalo: {_id: horse._id, codigo: horse.codigo, nome: horse.nome},
        avaliacaoInicial,
        dataInicio: toDate(input.dataInicio),
        dataFim: toDate(input.dataFim),
        planejamento: await buildPlanning(
          user.uid,
          input.treinosPorDia,
          horse._id,
          plan.planejamento
        ),
        atualizadoEm: now,
      };
      const edited: PlanDocument = {...plan, ...content};
      if (listPlannedDates(edited).length === 0) {
        throw new AppError("invalid-argument", NO_PLANNED_DATES_MESSAGE);
      }

      await updatePlanContent(plan._id, content, session);
      if (plan.status === "ATIVO") {
        await syncActivePlan(edited, plan.cavalo._id, horse, today, session);
      }
      return loadTrainingPlanDetails(edited, viewer, today, session);
    });
  } catch (error) {
    // Outro plano ativado no cavalo novo ao mesmo tempo.
    if (
      isDuplicateKeyError(error) &&
      (error as Error).message.includes("idx_planos_cavalo_ativo")
    ) {
      throw new AppError("failed-precondition", ACTIVE_PLAN_MESSAGE);
    }
    throw error;
  }
}
