// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Registro do feedback do treinador do plano.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import {getDayStart} from "../../../shared/utils/dates";
import {assertActiveAccount} from "../../horses";
import {findTrainingRecordById, saveTrainingFeedback} from "../../training";
import type {TrainingFeedback} from "../../training";
import type {FeedbackInput, TrainingRecordView} from "../types";
import {RECORD_NOT_FOUND_MESSAGE, resolveRecordViewer} from "./recordAccess";
import {
  ALREADY_FEEDBACK_MESSAGE,
  assertCanRegisterFeedback,
} from "./recordRules";
import {buildTrainingRecordView} from "./recordView";

/** Grava o feedback do treinador do plano em um treino com relato do
 * atleta. Depois do relato, só o próprio feedback muda o treino; por isso
 * basta a gravação condicional (feedback ausente) para garantir um único
 * feedback, mesmo com envios simultâneos.
 * @param {AuthenticatedUser} user Usuário autenticado.
 * @param {FeedbackInput} input Feedback validado.
 * @return {Promise<TrainingRecordView>} Treino já com o feedback.
 */
export async function registerTrainingFeedbackService(
  user: AuthenticatedUser,
  input: FeedbackInput
): Promise<TrainingRecordView> {
  const [record] = await Promise.all([
    findTrainingRecordById(input.registroId),
    assertActiveAccount(user.uid, user.role),
  ]);
  if (!record) throw new AppError("not-found", RECORD_NOT_FOUND_MESSAGE);
  const viewer = await resolveRecordViewer(user, record);
  assertCanRegisterFeedback(record, viewer);

  const feedback: TrainingFeedback = {
    data: new Date(),
    comentario: input.comentario,
    dificuldadesIdentificadas: input.dificuldadesIdentificadas,
    orientacoes: input.orientacoes,
  };
  if (!(await saveTrainingFeedback(record._id, user.uid, feedback))) {
    throw new AppError("failed-precondition", ALREADY_FEEDBACK_MESSAGE);
  }
  return buildTrainingRecordView({...record, feedback}, viewer, getDayStart());
}
