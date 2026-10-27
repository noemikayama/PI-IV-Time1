// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Uso da URL compartilhada do Identity Toolkit.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Uso de códigos previstos em AppErrorCode e padronização.
//
// Data: 14/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação da verificação de senha
// -----------------------------------------------------------------------------

import {
  identityToolkitUrl,
} from "../../../../shared/config/identityToolkit";
import {AppError} from "../../../../shared/errors/AppError";

type SignInResponse = {localId?: string; error?: {message?: string}};

/** Confere as credenciais no Identity Toolkit e devolve o UID.
 * @param {string} email E-mail informado no login.
 * @param {string} password Senha informada no login.
 */
export async function verifyPassword(
  email: string,
  password: string
): Promise<string> {
  const response = await fetch(identityToolkitUrl("signInWithPassword"), {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({email, password, returnSecureToken: true}),
  });
  const body = (await response.json()) as SignInResponse;

  if (response.ok && body.localId) return body.localId;

  const reason = body.error?.message ?? "";
  if (reason.startsWith("TOO_MANY_ATTEMPTS")) {
    throw new AppError(
      "permission-denied",
      "Muitas tentativas. Tente novamente mais tarde."
    );
  }
  if (reason.startsWith("USER_DISABLED")) {
    throw new AppError("permission-denied", "Conta desativada.");
  }
  // EMAIL_NOT_FOUND, INVALID_PASSWORD e INVALID_LOGIN_CREDENTIALS têm a mesma
  // resposta, para não revelar se o e-mail existe.
  throw new AppError("unauthenticated", "E-mail ou senha inválidos.");
}
