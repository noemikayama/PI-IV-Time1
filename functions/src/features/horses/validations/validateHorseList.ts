// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação da ordenação da lista de cavalos.
// Alteração: Busca opcional por nome do cavalo (RF04014).
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {asRecord, assertAllowedFields} from "../../authentication/shared";
import type {HorseListInput, HorseListOrder} from "../types";

const ORDERS: readonly HorseListOrder[] = [
  "A_Z",
  "Z_A",
  "MAIS_RECENTES",
  "MAIS_ANTIGOS",
];

// Mesmo limite do nome do cavalo.
const MAX_SEARCH_LENGTH = 80;

/** Valida a ordenação; sem ela, a lista vem em ordem alfabética (RF04012).
 * @param {unknown} value Valor recebido.
 * @return {HorseListOrder} Ordenação validada.
 */
function parseOrdenacao(value: unknown): HorseListOrder {
  if (value === undefined || value === null) return "A_Z";
  if (!ORDERS.includes(value as HorseListOrder)) {
    throw new AppError(
      "invalid-argument",
      `Ordenação inválida. Use ${ORDERS.join(", ")}.`
    );
  }
  return value as HorseListOrder;
}

/** Valida a busca por nome; ausente, nula ou vazia lista todos.
 * @param {unknown} value Valor recebido.
 * @return {string|undefined} Texto da busca, sem espaços nas pontas.
 */
function parseBusca(value: unknown): string | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "string") {
    throw new AppError("invalid-argument", "Busca inválida.");
  }
  if (value.length > MAX_SEARCH_LENGTH) {
    throw new AppError(
      "invalid-argument",
      `A busca deve ter no máximo ${MAX_SEARCH_LENGTH} caracteres.`
    );
  }
  const busca = value.trim();
  return busca === "" ? undefined : busca;
}

/** Valida a consulta da lista: ordenação e busca por nome, ambas opcionais.
 * @param {unknown} data Dados recebidos pelo endpoint (podem faltar).
 * @return {HorseListInput} Consulta validada.
 */
export function validateHorseList(data: unknown): HorseListInput {
  const record = asRecord(data ?? {}, "Dados da consulta inválidos.");
  assertAllowedFields(record, ["ordenacao", "busca"]);
  const busca = parseBusca(record.busca);
  return {
    ordenacao: parseOrdenacao(record.ordenacao),
    ...(busca && {busca}),
  };
}
