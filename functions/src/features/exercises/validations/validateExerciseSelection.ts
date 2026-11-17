// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação da galeria de exercícios e da lista de exercícios
// selecionados (tempo total e cadastro de treinamentos).
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {asRecord, assertAllowedFields} from "../../authentication/shared";
import type {ExerciseGalleryInput} from "../types";

// Mesmo limite do nome do exercício.
const MAX_SEARCH_LENGTH = 80;
// Exercícios de um treinamento.
export const MAX_SELECTED_EXERCISES = 50;

/** Cria um erro de argumento inválido com a mensagem informada.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro de argumento inválido.
 */
function invalid(message: string): AppError {
  return new AppError("invalid-argument", message);
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

/** Valida a lista de _id dos exercícios selecionados, na ordem de execução.
 * @param {unknown} value Valor recebido.
 * @param {number} min Quantidade mínima (1 no cadastro do treinamento).
 * @return {ObjectId[]} _id dos exercícios.
 */
export function parseExerciseIds(value: unknown, min: number): ObjectId[] {
  if (value === undefined || value === null) value = [];
  if (!Array.isArray(value)) {
    throw invalid("Exercícios: envie a lista de ids.");
  }
  if (value.length < min) {
    throw invalid("Selecione pelo menos um exercício.");
  }
  if (value.length > MAX_SELECTED_EXERCISES) {
    throw invalid(
      `Selecione no máximo ${MAX_SELECTED_EXERCISES} exercícios.`
    );
  }
  return value.map((id) => parseObjectId(id, "Exercício inválido."));
}

/** Valida a busca por nome; ausente, nula ou vazia lista todos.
 * @param {unknown} value Valor recebido.
 * @return {string|undefined} Texto da busca, sem espaços nas pontas.
 */
function parseBusca(value: unknown): string | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "string") throw invalid("Busca inválida.");
  if (value.length > MAX_SEARCH_LENGTH) {
    throw invalid(
      `A busca deve ter no máximo ${MAX_SEARCH_LENGTH} caracteres.`
    );
  }
  const busca = value.trim();
  return busca === "" ? undefined : busca;
}

/** Valida os filtros da galeria, ambos opcionais. Sem cavaloId (ausente,
 * nulo ou vazio), a galeria volta a listar os genéricos.
 * @param {unknown} data Dados recebidos pelo endpoint (podem faltar).
 * @return {ExerciseGalleryInput} Filtros validados.
 */
export function validateExerciseGallery(data: unknown): ExerciseGalleryInput {
  const record = asRecord(data ?? {}, "Dados da consulta inválidos.");
  assertAllowedFields(record, ["busca", "cavaloId"]);
  const busca = parseBusca(record.busca);
  const {cavaloId} = record;
  return {
    ...(busca && {busca}),
    cavaloId:
      cavaloId === undefined || cavaloId === null || cavaloId === "" ?
        null :
        parseObjectId(cavaloId, "Cavalo inválido."),
  };
}

/** Valida o pedido do tempo total. Lista vazia é aceita e soma 0.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {ObjectId[]} _id dos exercícios selecionados.
 */
export function validateExerciseDurationSum(data: unknown): ObjectId[] {
  const record = asRecord(data ?? {}, "Dados da consulta inválidos.");
  assertAllowedFields(record, ["exercicios"]);
  return parseExerciseIds(record.exercicios, 0);
}
