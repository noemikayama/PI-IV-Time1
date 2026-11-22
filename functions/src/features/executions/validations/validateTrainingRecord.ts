// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Validação do identificador do treino agendado e do pedido da
// lista de execuções que esperam feedback.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {asRecord, assertAllowedFields} from "../../authentication/shared";
import {parseObjectId} from "../../exercises";
import type {TrainingRecordInput} from "../types";

export const INVALID_DATA_MESSAGE = "Dados do treino inválidos.";

/** Valida o _id do treino agendado (registro de treino).
 * @param {unknown} value Valor recebido.
 * @return {ObjectId} _id convertido.
 */
export const parseRecordId = (value: unknown): ObjectId =>
  parseObjectId(value, "Identificador do treino inválido.");

/** Valida a consulta do treino agendado.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {TrainingRecordInput} _id do treino.
 */
export function validateTrainingRecordInput(
  data: unknown
): TrainingRecordInput {
  const record = asRecord(data ?? {}, INVALID_DATA_MESSAGE);
  assertAllowedFields(record, ["registroId"]);
  return {registroId: parseRecordId(record.registroId)};
}

/** Valida o pedido da lista de execuções que esperam feedback, que não
 * tem campos.
 * @param {unknown} data Dados recebidos pelo endpoint.
 */
export function validatePendingFeedbacksInput(data: unknown): void {
  const record = asRecord(data ?? {}, INVALID_DATA_MESSAGE);
  assertAllowedFields(record, []);
}
