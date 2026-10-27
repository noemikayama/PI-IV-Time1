// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação e remoção de contas no Firebase Authentication.
// -----------------------------------------------------------------------------

import {logger} from "firebase-functions";
import {auth} from "../../../../shared/config/firebase";
import type {Role} from "../../../../shared/constants/roles";
import {AppError} from "../../../../shared/errors/AppError";
import type {Credentials} from "../types";

/** Verifica se o erro contém o código solicitado.
 * @param {unknown} error Erro recebido.
 * @param {string} code Código procurado.
 * @return {boolean} Indica se os códigos correspondem.
 */
function hasCode(error: unknown, code: string): boolean {
  return typeof error === "object" && error !== null &&
        (error as {code?: unknown}).code === code;
}

/** Cria a conta no Firebase Auth e define sua role como custom claim.
 * @param {Credentials} credentials Credenciais da conta.
 * @param {Role} role Perfil de acesso da conta.
 */
export async function createAuthAccount(
  credentials: Credentials,
  role: Role
): Promise<string> {
  try {
    const user = await auth.createUser({
      email: credentials.email,
      password: credentials.senha,
      displayName: credentials.nome,
    });

    try {
      await auth.setCustomUserClaims(user.uid, {role});
    } catch (error) {
      await deleteAuthAccount(user.uid);
      throw error;
    }

    return user.uid;
  } catch (error) {
    if (hasCode(error, "auth/email-already-exists")) {
      throw new AppError("already-exists", "E-mail já cadastrado.");
    }
    throw error;
  }
}

/** Remove a conta do Firebase Auth durante a reversão de um cadastro.
 * @param {string} uid UID do usuário.
 */
export async function deleteAuthAccount(uid: string): Promise<void> {
  try {
    await auth.deleteUser(uid);
  } catch {
    logger.error(
      "Falha ao reverter usuário do Firebase Authentication",
      {uid}
    );
  }
}
