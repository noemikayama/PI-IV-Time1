// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conversão dos erros da aplicação para Cloud Functions.
// -----------------------------------------------------------------------------

import {logger} from "firebase-functions";
import {HttpsError} from "firebase-functions/v2/https";
import {AppError} from "./AppError";

// Converte qualquer erro em HttpsError. Em produção, erros inesperados são
// registrados apenas com o nome, sem expor URI, e-mails ou dados pessoais.
// No emulador local, a mensagem real também é registrada para
// facilitar o debug.
/** Converte erros da aplicação em erros compatíveis com o Firebase.
 * @param {unknown} error Erro recebido.
 * @return {HttpsError} Erro compatível com callable functions.
 */
export function mapErrorToHttpsError(error: unknown): HttpsError {
  if (error instanceof HttpsError) return error;
  if (error instanceof AppError) {
    return new HttpsError(error.code, error.message);
  }

  const isEmulator = process.env.FUNCTIONS_EMULATOR === "true";

  logger.error("Erro inesperado", {
    name: error instanceof Error ? error.name : typeof error,
    ...(isEmulator && {
      detail: error instanceof Error ? error.message : String(error),
    }),
  });

  return new HttpsError("internal", "Erro interno.");
}
