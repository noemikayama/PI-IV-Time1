// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Edição do treinamento, com a renovação das cópias nos planos em
// andamento e nos registros PLANEJADO a partir de hoje.
// -----------------------------------------------------------------------------

import {runInTransaction} from "../../../shared/config/mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {getDayStart} from "../../../shared/utils/dates";
import {findTrainerExercisesByCodes} from "../../exercises";
// Import direto do repository: o index.ts de planos importa esta feature.
import {
  ensurePlanIndexes,
  refreshPlanTrainingSnapshots,
} from "../../plans/repositories/planRepository";
import {
  ensureTrainingRecordIndexes,
  refreshPlannedRecordsTraining,
} from "../repositories/trainingRecordRepository";
import {updateTrainingContent} from "../repositories/trainingRepository";
import type {
  TrainingContent,
  TrainingDetailsResult,
  TrainingDocument,
  TrainingExercise,
  TrainingUpdateInput,
} from "../types";
import {toTrainingDetails} from "./getTrainingDetailsService";
import {loadAccessibleTraining} from "./trainingAccess";
import {
  toRecordTraining,
  toTrainingExercise,
  toTrainingSnapshot,
} from "./trainingSnapshot";

/** Monta a lista de exercícios na ordem recebida. Os que já estavam no
 * treinamento mantêm a cópia atual, mesmo que o exercício tenha sido
 * excluído depois. Os novos seguem a regra do cadastro: ativos e
 * cadastrados pelo treinador que edita. Exercício retirado só deixa a
 * lista; o documento em 'exercicios' não é tocado.
 * @param {TrainingDocument} training Treinamento atual.
 * @param {string} uid UID do treinador.
 * @param {number[]} codes Códigos na ordem de execução (podem repetir).
 * @return {Promise<TrainingExercise[]>} Exercícios do treinamento.
 */
async function resolveExercises(
  training: TrainingDocument,
  uid: string,
  codes: number[]
): Promise<TrainingExercise[]> {
  const byCode = new Map(
    training.exercicios.map((exercise) => [exercise.codigo, exercise])
  );
  const found = await findTrainerExercisesByCodes(
    uid,
    [...new Set(codes.filter((code) => !byCode.has(code)))]
  );
  for (const exercise of found) {
    byCode.set(exercise.codigo, toTrainingExercise(exercise));
  }

  // Não diferencia exercício inexistente de exercício de outro treinador,
  // para não revelar o acervo alheio.
  const missing = [...new Set(codes.filter((code) => !byCode.has(code)))];
  if (missing.length > 0) {
    throw new AppError(
      "invalid-argument",
      `Exercícios não encontrados: ${missing.join(", ")}.`
    );
  }
  return codes.map((code) => byCode.get(code) as TrainingExercise);
}

/** Substitui o treinamento pelo estado final da tela. Só o treinador que
 * criou o treinamento ou que treina um cavalo com ele agendado pode editar.
 * As cópias dos planos RASCUNHO/ATIVO e dos registros PLANEJADO de hoje em
 * diante, ainda sem exercício marcado, passam a ser a nova versão; o que já
 * passou ou já começou fica como estava.
 * @param {string} uid UID do treinador autenticado.
 * @param {TrainingUpdateInput} input Dados validados.
 * @return {Promise<TrainingDetailsResult>} Treinamento atualizado.
 */
export async function updateTrainingService(
  uid: string,
  input: TrainingUpdateInput
): Promise<TrainingDetailsResult> {
  const {training} = await loadAccessibleTraining(uid, input.codigo, true);
  const [exercicios] = await Promise.all([
    resolveExercises(training, uid, input.exercicioCodigos),
    ensureTrainingRecordIndexes(),
    ensurePlanIndexes(),
  ]);

  const now = new Date();
  const content: TrainingContent = {
    titulo: input.titulo,
    ...(input.descricao && {descricao: input.descricao}),
    orientacoes: input.orientacoes,
    duracaoEstimadaMinutos: input.duracaoEstimadaMinutos,
    exercicios,
    atualizadoEm: now,
  };
  const updated: TrainingDocument = {
    _id: training._id,
    codigo: training.codigo,
    treinador: training.treinador,
    criadoEm: training.criadoEm,
    ...content,
  };
  const snapshot = toTrainingSnapshot(updated);

  await runInTransaction(async (session) => {
    await updateTrainingContent(training._id, content, session);
    await refreshPlanTrainingSnapshots(snapshot, session);
    await refreshPlannedRecordsTraining(
      training._id,
      getDayStart(now),
      toRecordTraining(snapshot),
      session
    );
  });

  return toTrainingDetails(updated, "treinador");
}
