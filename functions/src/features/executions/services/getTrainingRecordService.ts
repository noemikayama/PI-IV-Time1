// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Consulta do treino agendado (getTrainingRecord).
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import {getDayStart} from "../../../shared/utils/dates";
import {assertActiveAccount} from "../../horses";
import {findTrainingRecordById} from "../../training";
import type {TrainingRecordInput, TrainingRecordView} from "../types";
import {RECORD_NOT_FOUND_MESSAGE, resolveRecordViewer} from "./recordAccess";
import {buildTrainingRecordView} from "./recordView";

/** Abre o treino agendado para quem tem acesso: a cópia do treino, os
 * materiais e as mídias dos exercícios, a execução, o feedback e as ações
 * permitidas. Conta inativa prevalece sobre treino inexistente.
 * @param {AuthenticatedUser} user Usuário autenticado.
 * @param {TrainingRecordInput} input _id do treino.
 * @return {Promise<TrainingRecordView>} Treino para o app.
 */
export async function getTrainingRecordService(
  user: AuthenticatedUser,
  input: TrainingRecordInput
): Promise<TrainingRecordView> {
  const [record] = await Promise.all([
    findTrainingRecordById(input.registroId),
    assertActiveAccount(user.uid, user.role),
  ]);
  if (!record) throw new AppError("not-found", RECORD_NOT_FOUND_MESSAGE);
  const viewer = await resolveRecordViewer(user, record);
  return buildTrainingRecordView(record, viewer, getDayStart());
}
