// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Atualização do nome exibido da conta, usada na edição do perfil.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Uso da checagem de código de erro compartilhada.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação e remoção de contas no Firebase Authentication.
// -----------------------------------------------------------------------------

import {logger} from "firebase-functions";
import {auth} from "../../../../shared/config/firebase";
import type {Role} from "../../../../shared/constants/roles";
import {AppError} from "../../../../shared/errors/AppError";
import {
  hasFirebaseErrorCode,
} from "../../../../shared/errors/firebaseErrorCode";
import type {Credentials} from "../types";

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
    if (hasFirebaseErrorCode(error, "auth/email-already-exists")) {
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

/** Atualiza o nome exibido da conta no Firebase Auth (cópia do perfil).
 * O nome válido é o do MongoDB, já gravado; a falha aqui só é registrada.
 * @param {string} uid UID do usuário.
 * @param {string} nome Novo nome.
 */
export async function updateAuthDisplayName(
  uid: string,
  nome: string
): Promise<void> {
  try {
    await auth.updateUser(uid, {displayName: nome});
  } catch {
    logger.error(
      "Falha ao atualizar o nome no Firebase Authentication",
      {uid}
    );
  }
}
