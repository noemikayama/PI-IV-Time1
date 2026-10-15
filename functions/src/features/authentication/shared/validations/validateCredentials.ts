// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Inclusão da validação dos dados de login.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação e normalização dos dados comuns de cadastro.
// -----------------------------------------------------------------------------

import {AppError} from "../../../../shared/errors/AppError";
import type {Credentials, LoginInput} from "../types";

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** Cria um erro de argumento inválido com a mensagem informada.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro de argumento inválido.
 */
function invalid(message: string): AppError {
  return new AppError("invalid-argument", message);
}

/** Garante que os dados recebidos sejam um objeto simples.
 * @param {unknown} data Dados recebidos.
 * @return {Object} Dados convertidos em objeto.
 */
export function asRecord(data: unknown): Record<string, unknown> {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    throw invalid("Dados de cadastro inválidos.");
  }
  return data as Record<string, unknown>;
}

/** Valida e normaliza as credenciais usadas no cadastro.
 * @param {Object} data Dados recebidos.
 * @return {Credentials} Credenciais validadas e normalizadas.
 */
export function parseCredentials(data: Record<string, unknown>): Credentials {
  const {nome, email, senha} = data;

  if (
    typeof nome !== "string" ||
    nome.trim().length < 3 ||
    nome.trim().length > 120
  ) {
    throw invalid("O nome deve ter entre 3 e 120 caracteres.");
  }
  if (
    typeof email !== "string" ||
    email.length > 254 ||
    !EMAIL_PATTERN.test(email.trim())
  ) {
    throw invalid("E-mail inválido.");
  }
  if (typeof senha !== "string" || senha.length < 8 || senha.length > 128) {
    throw invalid("A senha deve ter entre 8 e 128 caracteres.");
  }

  return {
    nome: nome.trim(),
    email: email.trim().toLowerCase(),
    senha,
  };
}

/** Valida e normaliza e-mail e senha para autenticação.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {LoginInput} Credenciais normalizadas para autenticação.
 */
export function validateLoginInput(data: unknown): LoginInput {
  const {email, senha} = (data ?? {}) as Partial<
    Record<keyof LoginInput, unknown>
  >;

  if (
    typeof email !== "string" || email.trim() === "" ||
    typeof senha !== "string" ||
    senha === ""
  ) {
    throw invalid("Informe e-mail e senha.");
  }

  return {email: email.trim().toLowerCase(), senha};
}
