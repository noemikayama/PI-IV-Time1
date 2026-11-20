// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação da edição de treinamentos, com as regras do cadastro.
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do cadastro de treinamentos.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {asRecord, assertAllowedFields} from "../../authentication/shared";
import {MAX_SELECTED_EXERCISES, parseExerciseIds} from "../../exercises";
import type {TrainingRegistrationInput, TrainingUpdateInput} from "../types";
import {parseCode} from "./validateTrainingDetails";

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

/** Valida os códigos dos exercícios da edição: strings só com dígitos, na
 * ordem de execução, com pelo menos um. Como no cadastro, um exercício pode
 * aparecer mais de uma vez.
 * @param {unknown} value Valor recebido.
 * @return {number[]} Códigos convertidos, na ordem recebida.
 */
function parseExerciseCodes(value: unknown): number[] {
  if (!Array.isArray(value)) {
    throw invalid("Exercícios: envie a lista de códigos.");
  }
  if (value.length < 1) throw invalid("Selecione pelo menos um exercício.");
  if (value.length > MAX_SELECTED_EXERCISES) {
    throw invalid(`Selecione no máximo ${MAX_SELECTED_EXERCISES} exercícios.`);
  }
  return value.map((item) => parseCode(item, "Código de exercício inválido."));
}

/** Valida a edição do treinamento: o estado final da tela, com as mesmas
 * regras de texto e duração do cadastro. Como a edição substitui tudo,
 * 'descricao' e 'orientacoes' são obrigatórias (aceitam "" e []): um campo
 * esquecido pelo app não apaga o conteúdo sem aviso.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {TrainingUpdateInput} Dados validados e normalizados.
 */
export function validateTrainingUpdate(data: unknown): TrainingUpdateInput {
  const record = asRecord(data ?? {}, "Dados da edição inválidos.");
  assertAllowedFields(record, [
    "codigo",
    "titulo",
    "descricao",
    "duracaoEstimada",
    "orientacoes",
    "exercicioCodigos",
  ]);
  if (typeof record.descricao !== "string") {
    throw invalid("Descrição: envie o texto (\"\" quando não houver).");
  }
  if (!Array.isArray(record.orientacoes)) {
    throw invalid("Orientações: envie a lista ([] quando não houver).");
  }
  const descricao = parseDescricao(record.descricao);
  return {
    codigo: parseCode(record.codigo, "Código do treinamento inválido."),
    titulo: parseText(record.titulo, "O título", 3, 80),
    ...(descricao && {descricao}),
    orientacoes: parseOrientacoes(record.orientacoes),
    duracaoEstimadaMinutos: parseDuracao(record.duracaoEstimada),
    exercicioCodigos: parseExerciseCodes(record.exercicioCodigos),
  };
}
