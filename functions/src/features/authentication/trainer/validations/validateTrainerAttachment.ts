// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação dos dados dos endpoints de anexos do treinador.
// -----------------------------------------------------------------------------

import {AppError} from "../../../../shared/errors/AppError";
import {asRecord} from "../../shared";
import type {
  AttachmentFileInput,
  AttachmentType,
  AttachmentUploadInput,
} from "../types";

/** Cria um erro de argumento inválido com a mensagem informada.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro de argumento inválido.
 */
function invalid(message: string): AppError {
  return new AppError("invalid-argument", message);
}

/** Valida o tipo do anexo.
 * @param {unknown} value Valor recebido.
 * @return {AttachmentType} Tipo validado.
 */
function parseTipo(value: unknown): AttachmentType {
  if (value !== "experiencias" && value !== "certificacoes") {
    throw invalid("Tipo de anexo inválido.");
  }
  return value;
}

/** Valida o caminho do arquivo. A posse do caminho é conferida no service.
 * @param {unknown} value Valor recebido.
 * @return {string} Caminho validado.
 */
function parseCaminho(value: unknown): string {
  if (
    typeof value !== "string" ||
    value.length > 200 ||
    !value.endsWith(".pdf") ||
    value.includes("..")
  ) {
    throw invalid("Caminho do arquivo inválido.");
  }
  return value;
}

/** Valida o pedido de URL de envio.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {AttachmentUploadInput} Dados validados.
 */
export function validateAttachmentUpload(data: unknown): AttachmentUploadInput {
  return {tipo: parseTipo(asRecord(data).tipo)};
}

/** Valida a confirmação de um envio.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {AttachmentFileInput} Dados validados.
 */
export function validateAttachmentConfirm(data: unknown): AttachmentFileInput {
  const record = asRecord(data);
  return {tipo: parseTipo(record.tipo), caminho: parseCaminho(record.caminho)};
}

/** Valida o pedido de remoção.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {AttachmentFileInput} Dados validados.
 */
export function validateAttachmentRemoval(data: unknown): AttachmentFileInput {
  const record = asRecord(data);
  return {tipo: parseTipo(record.tipo), caminho: parseCaminho(record.caminho)};
}
