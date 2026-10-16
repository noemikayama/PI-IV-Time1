// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Uso de código previsto em AppErrorCode e imports de ../types.
//
// Data: 14/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação da autenticação para login
// -----------------------------------------------------------------------------

import {auth} from "../../../../shared/config/firebase";
import {AppError} from "../../../../shared/errors/AppError";
import {findAccountByUid} from "../repositories/accountRepository";
import type {LoginInput, LoginResult} from "../types";
import {verifyPassword} from "./verifyPassword";

/** Autentica o usuário e cria o token customizado de acesso. */
export async function authenticateUser(
  {email, senha}: LoginInput
): Promise<LoginResult> {
  const uid = await verifyPassword(email, senha);

  const account = await findAccountByUid(uid);
  if (!account) {
    throw new AppError(
      "not-found",
      "Cadastro não encontrado para este e-mail."
    );
  }
  // Conta inativa não autentica, mas o histórico é preservado.
  if (!account.active) {
    throw new AppError("permission-denied", "Conta inativa.");
  }

  // A claim 'role' já é gravada no cadastro (createAuthAccount), repete no
  // custom token para manter o token consistente com requireAuthentication.
  const customToken = await auth.createCustomToken(uid, {role: account.role});

  return {customToken, role: account.role, nome: account.nome};
}
