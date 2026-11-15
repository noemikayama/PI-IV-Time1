// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação da criação e da consulta de avaliações.
// Alteração: Consulta do histórico removida (vem no perfil do cavalo).
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {getTodayYmd, isValidYmd} from "../../../shared/utils/dates";
import {asRecord, assertAllowedFields} from "../../authentication/shared";
import type {EvaluationCreateInput} from "../types";

const MAX_TEXT_LENGTH = 2000;
const MAX_ITEM_LENGTH = 500;
const MAX_OBSERVATIONS = 30;
const MAX_MODALITIES = 20;

/** Cria um erro de argumento inválido com a mensagem informada.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro de argumento inválido.
 */
function invalid(message: string): AppError {
  return new AppError("invalid-argument", message);
}

/** Valida um texto obrigatório e remove espaços nas pontas.
 * @param {unknown} value Valor recebido.
 * @param {string} label Nome do campo usado na mensagem.
 * @param {number} max Tamanho máximo.
 * @return {string} Texto normalizado.
 */
function parseText(value: unknown, label: string, max: number): string {
  const text = typeof value === "string" ? value.trim() : "";
  if (text.length < 1 || text.length > max) {
    throw invalid(`${label} deve ter entre 1 e ${max} caracteres.`);
  }
  return text;
}

/** Valida um texto opcional: ausente, nulo ou vazio vira undefined.
 * @param {unknown} value Valor recebido.
 * @param {string} label Nome do campo usado na mensagem.
 * @return {string|undefined} Texto normalizado.
 */
function parseOptionalText(
  value: unknown,
  label: string
): string | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value === "string" && value.trim() === "") return undefined;
  return parseText(value, label, MAX_TEXT_LENGTH);
}

/** Valida o _id (hexadecimal) de um documento.
 * @param {unknown} value Valor recebido.
 * @param {string} message Mensagem usada se o valor for inválido.
 * @return {ObjectId} _id convertido.
 */
function parseObjectId(value: unknown, message: string): ObjectId {
  if (typeof value !== "string" || !/^[0-9a-f]{24}$/i.test(value)) {
    throw invalid(message);
  }
  return new ObjectId(value);
}

/** Valida a data da avaliação (AAAA-MM-DD, não futura). A comparação com o
 * nascimento do cavalo é feita no service.
 * @param {unknown} value Valor recebido.
 * @return {string} Data validada.
 */
function parseDate(value: unknown): string {
  if (typeof value !== "string" || !isValidYmd(value)) {
    throw invalid("Data da avaliação inválida. Use o formato AAAA-MM-DD.");
  }
  if (value > getTodayYmd()) {
    throw invalid("A data da avaliação não pode estar no futuro.");
  }
  return value;
}

/** Valida as modalidades opcionais, sem repetição, na ordem informada.
 * @param {unknown} value Valor recebido.
 * @return {ObjectId[]} _ids das modalidades.
 */
function parseModalidadeIds(value: unknown): ObjectId[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > MAX_MODALITIES) {
    throw invalid(`Informe no máximo ${MAX_MODALITIES} modalidades.`);
  }
  const unique = [...new Set(value.map((id) => String(id).toLowerCase()))];
  return unique.map((id) => parseObjectId(id, "Modalidade inválida."));
}

/** Valida as observações opcionais, sem item vazio.
 * @param {unknown} value Valor recebido.
 * @return {string[]} Observações normalizadas.
 */
function parseObservacoes(value: unknown): string[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > MAX_OBSERVATIONS) {
    throw invalid(`Observações: informe no máximo ${MAX_OBSERVATIONS} itens.`);
  }
  return value.map((item) =>
    parseText(item, "Cada observação", MAX_ITEM_LENGTH)
  );
}

/** Valida a criação de uma avaliação (RF06001 e DD 2.4).
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {EvaluationCreateInput} Dados validados.
 */
export function validateEvaluationCreate(
  data: unknown
): EvaluationCreateInput {
  const record = asRecord(data, "Dados da avaliação inválidos.");
  assertAllowedFields(record, [
    "cavaloId",
    "data",
    "condicionamentoFisicoObservado",
    "limitacoes",
    "dificuldades",
    "modalidadeIds",
    "observacoes",
  ]);

  const limitacoes = parseOptionalText(record.limitacoes, "Limitações");
  const dificuldades = parseOptionalText(record.dificuldades, "Dificuldades");
  return {
    cavaloId: parseObjectId(record.cavaloId, "Cavalo inválido."),
    data: parseDate(record.data),
    condicionamentoFisicoObservado: parseText(
      record.condicionamentoFisicoObservado,
      "O condicionamento físico observado",
      MAX_TEXT_LENGTH
    ),
    ...(limitacoes && {limitacoes}),
    ...(dificuldades && {dificuldades}),
    modalidadeIds: parseModalidadeIds(record.modalidadeIds),
    observacoes: parseObservacoes(record.observacoes),
  };
}
