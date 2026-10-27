// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação da solicitação de recuperação de senha
// -----------------------------------------------------------------------------

import {logger} from "firebase-functions";
import {
  identityToolkitUrl,
} from "../../../../shared/config/identityToolkit";
import {AppError} from "../../../../shared/errors/AppError";
import type {PasswordResetInput, PasswordResetResult} from "../types";

type SendOobCodeResponse = {error?: {message?: string}};

// Mesma resposta para qualquer e-mail, com ou sem conta.
const GENERIC_MESSAGE =
  "Se houver uma conta associada a este e-mail, enviaremos as instruções " +
  "para redefinir a senha.";

// Recusas do Firebase que dependem do e-mail informado. Revelá-las permitiria
// descobrir quais e-mails possuem conta (inexistente, desativada ou com limite
// de envios já atingido), então são tratadas como sucesso.
const SILENT_REASONS = [
  "EMAIL_NOT_FOUND",
  "USER_DISABLED",
  "TOO_MANY_ATTEMPTS_TRY_LATER",
  "RESET_PASSWORD_EXCEED_LIMIT",
];

/** Pede ao Firebase Authentication o envio do e-mail de recuperação de senha.
 * O link e o e-mail são gerados pelo Firebase, conforme o template e a ação
 * configurados no Console do projeto.
 * @param {PasswordResetInput} input E-mail já validado e normalizado.
 * @return {PasswordResetResult} Mensagem genérica de confirmação.
 */
export async function sendPasswordReset(
  {email}: PasswordResetInput
): Promise<PasswordResetResult> {
  const response = await fetch(identityToolkitUrl("sendOobCode"), {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({requestType: "PASSWORD_RESET", email}),
  });

  if (response.ok) return {mensagem: GENERIC_MESSAGE};

  const body = (await response.json().catch(() => ({}))) as SendOobCodeResponse;
  const reason = body.error?.message ?? "";

  if (SILENT_REASONS.some((silent) => reason.startsWith(silent))) {
    // Sem o e-mail no log, para não gravar dado pessoal nem a enumeração.
    logger.info("Recuperação de senha não enviada", {reason});
    return {mensagem: GENERIC_MESSAGE};
  }
  if (reason.startsWith("INVALID_EMAIL")) {
    throw new AppError("invalid-argument", "E-mail inválido.");
  }

  // Falhas de configuração (chave inválida, provedor desativado, cota) não
  // dependem do e-mail informado; viram erro interno, sem detalhes.
  logger.error("Falha ao solicitar recuperação de senha", {
    status: response.status,
    reason,
  });
  throw new AppError("internal", "Erro interno.");
}
