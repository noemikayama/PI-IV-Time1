// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação dos dados da edição do perfil do responsável.
// -----------------------------------------------------------------------------

import {asRecord, assertAllowedFields, parseFullName} from "../../shared";
import type {UpdateGuardianProfileInput} from "../types";

// Apenas o nome é editável. _id, codigo, email, senha, situacaoCadastral,
// cavalos, modalidades e as datas são recusados.
const EDITABLE_FIELDS = ["nome", "sobrenome"];

/** Valida a edição do perfil: nome e sobrenome, gravados juntos em 'nome'.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {UpdateGuardianProfileInput} Nome completo validado.
 */
export function validateGuardianProfileUpdate(
  data: unknown
): UpdateGuardianProfileInput {
  const record = asRecord(data);
  assertAllowedFields(record, EDITABLE_FIELDS);
  return {nome: parseFullName(record.nome, record.sobrenome)};
}
