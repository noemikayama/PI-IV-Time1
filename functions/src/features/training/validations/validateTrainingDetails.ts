// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação da consulta de detalhes do treinamento.
// Alteração: Validação de código exportada para a edição do treinamento.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {asRecord, assertAllowedFields} from "../../authentication/shared";
import type {TrainingDetailsInput} from "../types";

/** Valida um código sequencial: string só com dígitos (espaços nas pontas
 * são removidos), representando um inteiro maior que zero.
 * @param {unknown} value Valor recebido.
 * @param {string} message Mensagem do erro.
 * @return {number} Código convertido.
 */
export function parseCode(value: unknown, message: string): number {
  const text = typeof value === "string" ? value.trim() : "";
  const codigo = /^\d{1,15}$/.test(text) ? Number(text) : 0;
  if (codigo < 1) throw new AppError("invalid-argument", message);
  return codigo;
}

/** Valida os dados da consulta de detalhes do treinamento.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {TrainingDetailsInput} Código do treinamento.
 */
export function validateTrainingDetailsInput(
  data: unknown
): TrainingDetailsInput {
  const record = asRecord(data ?? {}, "Dados da consulta inválidos.");
  assertAllowedFields(record, ["codigo"]);
  return {
    codigo: parseCode(record.codigo, "Código do treinamento inválido."),
  };
}
