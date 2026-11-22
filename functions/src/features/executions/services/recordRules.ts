// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Regras do treino agendado: situação exibida, relato do atleta,
// ações permitidas e conferências da execução e do feedback.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {REPORTED_STATUSES} from "../../training";
import type {
  ReportedRecordStatus,
  TrainingRecordDocument,
  TrainingRecordStatus,
} from "../../training";
import type {ExecutionMark, RecordPermissions, RecordViewer} from "../types";

// Fonte única das regras: a visualização usa as permissões, e as gravações,
// as conferências. Assim o botão do app e a recusa do servidor não divergem.

export const NOT_ATHLETE_MESSAGE =
  "Apenas o atleta do cavalo pode registrar a execução do treino.";
export const CANCELED_MESSAGE = "Este treino foi cancelado.";
export const NOT_TODAY_MESSAGE =
  "Só é possível registrar a execução do treino de hoje.";
export const ALREADY_EXECUTED_MESSAGE =
  "A execução deste treino já foi registrada.";
export const EXERCISES_CHANGED_MESSAGE =
  "Os exercícios deste treino mudaram. Abra o treino de novo para " +
  "registrar a execução.";
export const NOT_PLAN_TRAINER_MESSAGE =
  "Apenas o treinador do plano pode registrar o feedback.";
export const ALREADY_FEEDBACK_MESSAGE = "Este treino já possui um feedback.";
export const NO_REPORT_MESSAGE =
  "O feedback só pode ser registrado depois da execução do treino.";

const precondition = (message: string): AppError =>
  new AppError("failed-precondition", message);

/** Situação mostrada ao app: um treino de dia anterior que continua
 * PLANEJADO não foi feito e aparece como NAO_REALIZADO, como na agenda.
 * @param {TrainingRecordDocument} record Treino agendado.
 * @param {Date} today Hoje (meia-noite UTC, como getDayStart()).
 * @return {TrainingRecordStatus} Situação exibida.
 */
export const displayedStatus = (
  record: TrainingRecordDocument,
  today: Date
): TrainingRecordStatus =>
  record.status === "PLANEJADO" && record.dataPlanejada < today ?
    "NAO_REALIZADO" :
    record.status;

/** Se o treino tem relato do atleta. REALIZADO e PARCIAL só existem por
 * relato, mesmo num registro antigo sem 'dataExecucao'. O NAO_REALIZADO
 * precisa dela: o encerramento e o cancelamento do plano gravam
 * NAO_REALIZADO sem 'dataExecucao', e o relato sempre a grava.
 * @param {TrainingRecordDocument} record Treino agendado.
 * @return {boolean} Se há relato do atleta.
 */
export function hasAthleteReport(record: TrainingRecordDocument): boolean {
  if (!REPORTED_STATUSES.includes(record.status as ReportedRecordStatus)) {
    return false;
  }
  return record.status !== "NAO_REALIZADO" ||
    (record.dataExecucao !== undefined && record.dataExecucao !== null);
}

/** Se o treino é do dia informado (datas de calendário à meia-noite UTC).
 * @param {TrainingRecordDocument} record Treino agendado.
 * @param {Date} today Hoje (meia-noite UTC).
 * @return {boolean} Se o treino é de hoje.
 */
const isToday = (record: TrainingRecordDocument, today: Date): boolean =>
  record.dataPlanejada.getTime() === today.getTime();

/** Ações que o app pode oferecer a quem consulta.
 * @param {TrainingRecordDocument} record Treino agendado.
 * @param {RecordViewer} viewer Relação de quem consulta com o treino.
 * @param {Date} today Hoje (meia-noite UTC).
 * @return {RecordPermissions} Ações permitidas.
 */
export function recordPermissions(
  record: TrainingRecordDocument,
  viewer: RecordViewer,
  today: Date
): RecordPermissions {
  return {
    podeRegistrarExecucao: viewer.isAthlete &&
      record.status === "PLANEJADO" &&
      isToday(record, today),
    podeRegistrarFeedback: viewer.isPlanTrainer &&
      hasAthleteReport(record) &&
      !record.feedback,
  };
}

/** Confere se quem envia pode registrar a execução agora. A ordem define a
 * mensagem: relação, cancelamento, dia e, por último, execução anterior.
 * @param {TrainingRecordDocument} record Treino agendado.
 * @param {RecordViewer} viewer Relação de quem envia com o treino.
 * @param {Date} today Hoje (meia-noite UTC).
 */
export function assertCanRegisterExecution(
  record: TrainingRecordDocument,
  viewer: RecordViewer,
  today: Date
): void {
  if (!viewer.isAthlete) {
    throw new AppError("permission-denied", NOT_ATHLETE_MESSAGE);
  }
  if (record.status === "CANCELADO") throw precondition(CANCELED_MESSAGE);
  if (!isToday(record, today)) throw precondition(NOT_TODAY_MESSAGE);
  if (record.status !== "PLANEJADO") {
    throw precondition(ALREADY_EXECUTED_MESSAGE);
  }
}

/** Confere se as marcações correspondem aos exercícios atuais do treino,
 * posição por posição. A edição do treinamento ou do plano pode ter
 * renovado a cópia depois que o atleta abriu o treino.
 * @param {TrainingRecordDocument} record Treino agendado.
 * @param {ExecutionMark[]} marks Marcações, na ordem do treino.
 */
export function assertSameExercises(
  record: TrainingRecordDocument,
  marks: ExecutionMark[]
): void {
  const same = record.exercicios.length === marks.length &&
    record.exercicios.every(
      (item, index) => item.exercicio.codigo === marks[index].codigo
    );
  if (!same) throw precondition(EXERCISES_CHANGED_MESSAGE);
}

/** Confere se quem envia pode registrar o feedback do treino.
 * @param {TrainingRecordDocument} record Treino agendado.
 * @param {RecordViewer} viewer Relação de quem envia com o treino.
 */
export function assertCanRegisterFeedback(
  record: TrainingRecordDocument,
  viewer: RecordViewer
): void {
  if (!viewer.isPlanTrainer) {
    throw new AppError("permission-denied", NOT_PLAN_TRAINER_MESSAGE);
  }
  if (record.feedback) throw precondition(ALREADY_FEEDBACK_MESSAGE);
  if (!hasAthleteReport(record)) throw precondition(NO_REPORT_MESSAGE);
}
