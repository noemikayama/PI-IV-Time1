// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação dos dados dos endpoints de imagens do cavalo.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {asRecord} from "../../authentication/shared";
import {IMAGE_EXTENSIONS} from "../constants/images";
import type {
  HorseImageContentType,
  HorseImageFileInput,
  HorseImageUploadInput,
} from "../types";
import {validateHorseId} from "./validateHorse";

const CONTENT_TYPES = Object.keys(IMAGE_EXTENSIONS) as HorseImageContentType[];

/** Cria um erro de argumento inválido com a mensagem informada.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro de argumento inválido.
 */
function invalid(message: string): AppError {
  return new AppError("invalid-argument", message);
}

/** Valida o formato da imagem (JPEG ou PNG).
 * @param {unknown} value Valor recebido.
 * @return {HorseImageContentType} Formato validado.
 */
function parseContentType(value: unknown): HorseImageContentType {
  if (!CONTENT_TYPES.includes(value as HorseImageContentType)) {
    throw invalid("Formato de imagem inválido. Use JPEG ou PNG.");
  }
  return value as HorseImageContentType;
}

/** Valida o caminho da imagem. A posse do caminho é conferida no service.
 * @param {unknown} value Valor recebido.
 * @return {string} Caminho validado.
 */
function parseCaminho(value: unknown): string {
  if (
    typeof value !== "string" ||
    value.length > 200 ||
    !/\.(jpg|png)$/.test(value) ||
    value.includes("..")
  ) {
    throw invalid("Caminho da imagem inválido.");
  }
  return value;
}

/** Valida o pedido de URL de envio.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {HorseImageUploadInput} Dados validados.
 */
export function validateHorseImageUpload(
  data: unknown
): HorseImageUploadInput {
  const record = asRecord(data);
  return {
    id: validateHorseId(record),
    contentType: parseContentType(record.contentType),
  };
}

/** Valida a confirmação de um envio ou o pedido de remoção.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {HorseImageFileInput} Dados validados.
 */
export function validateHorseImageFile(data: unknown): HorseImageFileInput {
  const record = asRecord(data);
  return {id: validateHorseId(record), caminho: parseCaminho(record.caminho)};
}
