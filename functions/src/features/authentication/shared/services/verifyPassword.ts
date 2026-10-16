// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Uso de códigos previstos em AppErrorCode e padronização.
//
// Data: 14/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação da verificação de senha
// -----------------------------------------------------------------------------

import {WEB_API_KEY} from "../../../../shared/config/environment";
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
  const emulatorHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const baseUrl = emulatorHost ?
    `http://${emulatorHost}/identitytoolkit.googleapis.com` :
    "https://identitytoolkit.googleapis.com";

  const response = await fetch(
    `${baseUrl}/v1/accounts:signInWithPassword?key=${WEB_API_KEY.value()}`,
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({email, password, returnSecureToken: true}),
    }
  );
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
