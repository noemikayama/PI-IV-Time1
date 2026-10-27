// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação dos dados da edição de modalidades do responsável.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {AppError} from "../../../../shared/errors/AppError";
import {asRecord} from "../../shared";
import type {UpdateGuardianModalitiesInput} from "../types";

const MAX_MODALITY_IDS = 50;
const OBJECT_ID_PATTERN = /^[0-9a-fA-F]{24}$/;

/** Cria um erro de argumento inválido com a mensagem informada.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro de argumento inválido.
 */
function invalid(message: string): AppError {
  return new AppError("invalid-argument", message);
}

/** Valida e normaliza os IDs de modalidades informados na edição.
 * Lista vazia é válida e remove todos os vínculos; IDs repetidos são
 * unificados e a ordem da primeira ocorrência é mantida.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {UpdateGuardianModalitiesInput} IDs únicos como ObjectId.
 */
export function validateGuardianModalities(
  data: unknown
): UpdateGuardianModalitiesInput {
  const {modalidadeIds} = asRecord(data);

  if (
    !Array.isArray(modalidadeIds) ||
    modalidadeIds.length > MAX_MODALITY_IDS
  ) {
    throw invalid("Modalidades inválidas.");
  }

  const unique = new Map<string, ObjectId>();
  for (const item of modalidadeIds) {
    // ObjectId.isValid aceitaria números e strings de 12 caracteres.
    if (typeof item !== "string" || !OBJECT_ID_PATTERN.test(item)) {
      throw invalid("Modalidades inválidas.");
    }
    const id = new ObjectId(item);
    unique.set(id.toHexString(), id);
  }

  return {modalidadeIds: [...unique.values()]};
}
