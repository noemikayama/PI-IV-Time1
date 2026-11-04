// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da validação de e-mail, usada nos vínculos do cavalo.
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do nome completo (nome + sobrenome) e dos campos
// permitidos, compartilhadas pelas edições de perfil.
//
// Data: 20/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do e-mail da recuperação de senha, com a checagem de
// e-mail extraída para reaproveitamento no cadastro.
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
import type {Credentials, LoginInput, PasswordResetInput} from "../types";

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
 * @param {string} message Mensagem do erro; campos aninhados informam a sua.
 * @return {Object} Dados convertidos em objeto.
 */
export function asRecord(
  data: unknown,
  message = "Dados de cadastro inválidos."
): Record<string, unknown> {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    throw invalid(message);
  }
  return data as Record<string, unknown>;
}

/** Valida o formato do e-mail e o normaliza.
 * @param {unknown} email E-mail recebido.
 * @return {string} E-mail sem espaços e em minúsculas.
 */
export function parseEmail(email: unknown): string {
  if (
    typeof email !== "string" ||
    email.length > 254 ||
    !EMAIL_PATTERN.test(email.trim())
  ) {
    throw invalid("E-mail inválido.");
  }
  return email.trim().toLowerCase();
}

/** Recusa qualquer campo fora da lista de campos permitidos.
 * @param {Object} data Dados recebidos.
 * @param {string[]} allowed Campos aceitos pelo endpoint.
 */
export function assertAllowedFields(
  data: Record<string, unknown>,
  allowed: readonly string[]
): void {
  const blocked = Object.keys(data).find((field) => !allowed.includes(field));
  if (blocked !== undefined) {
    throw invalid(`O campo '${blocked}' não pode ser editado.`);
  }
}

/** Valida o nome da conta e remove espaços nas pontas.
 * @param {unknown} nome Nome recebido.
 * @return {string} Nome normalizado.
 */
function parseName(nome: unknown): string {
  if (
    typeof nome !== "string" ||
    nome.trim().length < 3 ||
    nome.trim().length > 120
  ) {
    throw invalid("O nome deve ter entre 3 e 120 caracteres.");
  }
  return nome.trim();
}

/** Junta nome e sobrenome como o app faz no cadastro ('<nome> <sobrenome>') e
 * valida o resultado com a mesma regra do campo 'nome'.
 * @param {unknown} nome Nome recebido.
 * @param {unknown} sobrenome Sobrenome recebido.
 * @return {string} Nome completo normalizado.
 */
export function parseFullName(nome: unknown, sobrenome: unknown): string {
  if (
    typeof nome !== "string" || nome.trim() === "" ||
    typeof sobrenome !== "string" || sobrenome.trim() === ""
  ) {
    throw invalid("Informe o nome e o sobrenome.");
  }
  return parseName(`${nome.trim()} ${sobrenome.trim()}`);
}

/** Valida e normaliza as credenciais usadas no cadastro.
 * @param {Object} data Dados recebidos.
 * @return {Credentials} Credenciais validadas e normalizadas.
 */
export function parseCredentials(data: Record<string, unknown>): Credentials {
  const {nome, email, senha} = data;

  const normalizedName = parseName(nome);
  const normalizedEmail = parseEmail(email);
  if (typeof senha !== "string" || senha.length < 8 || senha.length > 128) {
    throw invalid("A senha deve ter entre 8 e 128 caracteres.");
  }

  return {
    nome: normalizedName,
    email: normalizedEmail,
    senha,
  };
}

/** Valida e normaliza o e-mail da recuperação de senha. O formato é a única
 * checagem: a existência da conta nunca é verificada nem revelada.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {PasswordResetInput} E-mail normalizado.
 */
export function validatePasswordResetInput(
  data: unknown
): PasswordResetInput {
  return {email: parseEmail(asRecord(data).email)};
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
