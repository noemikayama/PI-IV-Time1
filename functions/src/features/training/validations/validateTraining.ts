// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do cadastro de treinamentos.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {asRecord} from "../../authentication/shared";
import {parseExerciseIds} from "../../exercises";
import type {TrainingRegistrationInput} from "../types";

const MAX_ORIENTATIONS = 30;
const MAX_ITEM_LENGTH = 500;
const MAX_DESCRIPTION_LENGTH = 1000;
// 8 horas.
const MAX_DURATION_MINUTES = 480;

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
 * @param {number} min Tamanho mínimo.
 * @param {number} max Tamanho máximo.
 * @return {string} Texto normalizado.
 */
function parseText(
  value: unknown,
  label: string,
  min: number,
  max: number
): string {
  const text = typeof value === "string" ? value.trim() : "";
  if (text.length < min || text.length > max) {
    throw invalid(`${label} deve ter entre ${min} e ${max} caracteres.`);
  }
  return text;
}

/** Valida a descrição (opcional): ausente, nula ou só com espaços é
 * omitida do documento.
 * @param {unknown} value Valor recebido.
 * @return {string|undefined} Descrição normalizada.
 */
function parseDescricao(value: unknown): string | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "string") throw invalid("Descrição inválida.");
  const descricao = value.trim();
  if (descricao === "") return undefined;
  return parseText(descricao, "A descrição", 1, MAX_DESCRIPTION_LENGTH);
}

/** Valida as orientações (opcionais, lista vazia aceita), sem itens vazios.
 * @param {unknown} value Valor recebido.
 * @return {string[]} Orientações normalizadas.
 */
function parseOrientacoes(value: unknown): string[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > MAX_ORIENTATIONS) {
    throw invalid(
      `Orientações: informe no máximo ${MAX_ORIENTATIONS} itens.`
    );
  }
  return value.map((item) =>
    parseText(item, "Cada orientação", 1, MAX_ITEM_LENGTH)
  );
}

/** Valida a duração estimada: inteiro maior que zero, em minutos. Não é
 * comparada com a soma dos exercícios (DD: pode incluir descansos e
 * deslocamentos).
 * @param {unknown} value Valor recebido.
 * @return {number} Duração em minutos.
 */
function parseDuracao(value: unknown): number {
  if (
    typeof value !== "number" ||
    !Number.isInteger(value) ||
    value < 1 ||
    value > MAX_DURATION_MINUTES
  ) {
    throw invalid(
      "A duração estimada deve ser um número inteiro de minutos entre 1 " +
        `e ${MAX_DURATION_MINUTES}.`
    );
  }
  return value;
}

/** Valida e normaliza os dados do cadastro de treinamento.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {TrainingRegistrationInput} Dados validados e normalizados.
 */
export function validateTrainingRegistration(
  data: unknown
): TrainingRegistrationInput {
  const record = asRecord(data);
  const descricao = parseDescricao(record.descricao);
  return {
    titulo: parseText(record.titulo, "O título", 3, 80),
    ...(descricao && {descricao}),
    orientacoes: parseOrientacoes(record.orientacoes),
    duracaoEstimadaMinutos: parseDuracao(record.duracaoEstimadaMinutos),
    exercicios: parseExerciseIds(record.exercicios, 1),
  };
}
