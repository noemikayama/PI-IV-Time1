// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Identificação de violação de índice único do MongoDB.
// -----------------------------------------------------------------------------

import {MongoServerError} from "mongodb";

const DUPLICATE_KEY = 11000;

/** Indica se o erro é de chave duplicada (índice único).
 * @param {unknown} error Erro capturado.
 * @return {boolean} true se for violação de índice único.
 */
export function isDuplicateKeyError(error: unknown): boolean {
  return error instanceof MongoServerError && error.code === DUPLICATE_KEY;
}
