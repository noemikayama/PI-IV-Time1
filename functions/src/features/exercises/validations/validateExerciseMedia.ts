// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 07/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação dos dados dos endpoints de mídias do exercício.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {asRecord} from "../../authentication/shared";
import {MEDIA_FIELDS} from "../constants/media";
import type {
  ExerciseMediaContentType,
  ExerciseMediaFileInput,
  ExerciseMediaUploadInput,
} from "../types";
import {validateExerciseId} from "./validateExercise";

const CONTENT_TYPES = Object.keys(MEDIA_FIELDS) as ExerciseMediaContentType[];

/** Cria um erro de argumento inválido com a mensagem informada.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro de argumento inválido.
 */
function invalid(message: string): AppError {
  return new AppError("invalid-argument", message);
}

/** Valida o formato da mídia (JPEG, PNG ou MP4).
 * @param {unknown} value Valor recebido.
 * @return {ExerciseMediaContentType} Formato validado.
 */
function parseContentType(value: unknown): ExerciseMediaContentType {
  if (!CONTENT_TYPES.includes(value as ExerciseMediaContentType)) {
    throw invalid("Formato de mídia inválido. Use JPEG, PNG ou MP4.");
  }
  return value as ExerciseMediaContentType;
}

/** Valida o caminho da mídia. A posse do caminho é conferida no service.
 * @param {unknown} value Valor recebido.
 * @return {string} Caminho validado.
 */
function parseCaminho(value: unknown): string {
  if (
    typeof value !== "string" ||
    value.length > 200 ||
    !/\.(jpg|png|mp4)$/.test(value) ||
    value.includes("..")
  ) {
    throw invalid("Caminho da mídia inválido.");
  }
  return value;
}

/** Valida o pedido de URL de envio.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {ExerciseMediaUploadInput} Dados validados.
 */
export function validateExerciseMediaUpload(
  data: unknown
): ExerciseMediaUploadInput {
  const record = asRecord(data);
  return {
    id: validateExerciseId(record),
    contentType: parseContentType(record.contentType),
  };
}

/** Valida a confirmação de um envio ou o pedido de remoção.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {ExerciseMediaFileInput} Dados validados.
 */
export function validateExerciseMediaFile(
  data: unknown
): ExerciseMediaFileInput {
  const record = asRecord(data);
  return {
    id: validateExerciseId(record),
    caminho: parseCaminho(record.caminho),
  };
}
