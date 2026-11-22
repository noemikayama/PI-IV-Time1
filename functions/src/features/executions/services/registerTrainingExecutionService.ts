// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Registro da execução do treino pelo atleta, em transação.
// -----------------------------------------------------------------------------

import {runInTransaction} from "../../../shared/config/mongodb";
import {AppError} from "../../../shared/errors/AppError";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import {getDayStart} from "../../../shared/utils/dates";
import {assertActiveAccount} from "../../horses";
import type {AccountRef} from "../../horses";
import {findTrainingRecordById, saveTrainingExecution} from "../../training";
import type {ExecutionReport, TrainingRecordDocument} from "../../training";
import type {ExecutionInput, TrainingRecordView} from "../types";
import {RECORD_NOT_FOUND_MESSAGE, resolveRecordViewer} from "./recordAccess";
import {
  ALREADY_EXECUTED_MESSAGE,
  assertCanRegisterExecution,
  assertSameExercises,
} from "./recordRules";
import {buildTrainingRecordView} from "./recordView";

/** Monta os campos gravados pela execução. A data é a de hoje (o app não a
 * envia), e quem enviou passa a ser o atleta do treino.
 * @param {TrainingRecordDocument} record Treino lido na transação.
 * @param {ExecutionInput} input Execução validada.
 * @param {AccountRef} athlete Conta de quem envia.
 * @param {Date} today Hoje (meia-noite UTC).
 * @return {ExecutionReport} Campos da execução.
 */
function toExecutionReport(
  record: TrainingRecordDocument,
  input: ExecutionInput,
  athlete: AccountRef,
  today: Date
): ExecutionReport {
  return {
    status: input.status,
    dataExecucao: today,
    ...(input.duracaoEfetiva !== undefined &&
      {duracaoEfetivaMinutos: input.duracaoEfetiva}),
    ...(input.percepcaoDesempenho !== undefined &&
      {percepcaoDesempenho: input.percepcaoDesempenho}),
    ...(input.dificuldades && {dificuldade: input.dificuldades}),
    ...(input.observacoes.length > 0 && {observacoes: input.observacoes}),
    // A cópia de cada exercício não muda; só a marcação da posição.
    exercicios: record.exercicios.map((item, index) => {
      const mark = input.exercicios[index];
      return {
        exercicio: item.exercicio,
        realizacao: mark.realizacao,
        ...(mark.observacao && {observacoesEspecificas: mark.observacao}),
      };
    }),
    responsavel: athlete,
  };
}

/** Grava a execução do treino de hoje, de uma vez. A leitura, as
 * conferências e a gravação ficam na mesma transação: se a edição ou o
 * cancelamento do plano, a edição do treinamento ou outro envio gravarem o
 * treino antes, o conflito de escrita repete tudo, e a nova leitura dá a
 * recusa certa.
 * @param {AuthenticatedUser} user Usuário autenticado.
 * @param {ExecutionInput} input Execução validada.
 * @return {Promise<TrainingRecordView>} Treino já com a execução.
 */
export async function registerTrainingExecutionService(
  user: AuthenticatedUser,
  input: ExecutionInput
): Promise<TrainingRecordView> {
  const athlete = await assertActiveAccount(user.uid, user.role);
  const today = getDayStart();
  const saved = await runInTransaction(async (session) => {
    const record = await findTrainingRecordById(input.registroId, session);
    if (!record) throw new AppError("not-found", RECORD_NOT_FOUND_MESSAGE);
    const viewer = await resolveRecordViewer(user, record, session);
    assertCanRegisterExecution(record, viewer, today);
    assertSameExercises(record, input.exercicios);
    const report = toExecutionReport(record, input, athlete, today);
    if (!(await saveTrainingExecution(record._id, report, session))) {
      throw new AppError("failed-precondition", ALREADY_EXECUTED_MESSAGE);
    }
    return {record: {...record, ...report}, viewer};
  });
  return buildTrainingRecordView(saved.record, saved.viewer, today);
}
