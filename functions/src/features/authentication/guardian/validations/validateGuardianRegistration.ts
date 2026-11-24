// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação dos dados enviados no cadastro de responsáveis.
// -----------------------------------------------------------------------------

import {asRecord, parseCredentials} from "../../shared";
import type {GuardianRegistrationInput} from "../types";

/** Valida e normaliza os dados do cadastro de responsável.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {GuardianRegistrationInput} Dados validados e normalizados.
 */
export function validateGuardianRegistration(
  data: unknown
): GuardianRegistrationInput {
  return parseCredentials(asRecord(data));
}
