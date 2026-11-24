// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do encerramento de sessão (logout)
// -----------------------------------------------------------------------------

import {auth} from "../../../../shared/config/firebase";
import {AppError} from "../../../../shared/errors/AppError";
import {
  hasFirebaseErrorCode,
} from "../../../../shared/errors/firebaseErrorCode";
import type {LogoutResult} from "../types";

/** Revoga todos os refresh tokens do usuário no Firebase Authentication.
 * O UID deve vir sempre do contexto autenticado (requireAuthentication),
 * nunca do corpo da requisição.
 * @param {string} uid UID do usuário autenticado.
 * @return {LogoutResult} Mensagem de confirmação.
 */
export async function revokeUserSessions(uid: string): Promise<LogoutResult> {
  try {
    await auth.revokeRefreshTokens(uid);
  } catch (error) {
    // Token válido de uma conta já removida.
    if (hasFirebaseErrorCode(error, "auth/user-not-found")) {
      throw new AppError("unauthenticated", "Faça login para continuar.");
    }
    throw error;
  }
  return {mensagem: "Sessão encerrada."};
}
