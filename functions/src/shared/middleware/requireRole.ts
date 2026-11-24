// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do middleware de permissões.
// -----------------------------------------------------------------------------

import type {CallableRequest} from "firebase-functions/v2/https";
import {AppError} from "../errors/AppError";
import {requireAuthentication} from "./requireAuthentication";
import type {AuthenticatedUser} from "./requireAuthentication";

/** Exige login e valida o claim 'role' do token.
 * @param {CallableRequest} request Requisição callable.
 * @param {string} role Perfil de acesso esperado.
 * @return {AuthenticatedUser} Contexto autenticado.
 */
export function requireRole(
  request: CallableRequest,
  role: string
): AuthenticatedUser {
  const user = requireAuthentication(request);
  if (user.role !== role) {
    throw new AppError(
      "permission-denied",
      "Acesso não permitido para este perfil."
    );
  }
  return user;
}
