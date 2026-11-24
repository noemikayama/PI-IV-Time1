// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Validação da execução do treino, com a situação deduzida das
// marcações dos exercícios.
// -----------------------------------------------------------------------------

import {asRecord, assertAllowedFields} from "../../authentication/shared";
import {MAX_SELECTED_EXERCISES} from "../../exercises";
import {parseCode} from "../../training";
import type {ReportedRecordStatus} from "../../training";
import {
  MAX_DIFFICULTIES_LENGTH,
  MAX_EFFECTIVE_MINUTES,
  MAX_EXERCISE_NOTE_LENGTH,
  MAX_PERCEPTION,
  MIN_PERCEPTION,
} from "../constants/limits";
import type {ExecutionInput, ExecutionMark, MarkedCompletion} from "../types";
import {invalid, parseOptionalText, parseTextList} from "./textFields";
import {INVALID_DATA_MESSAGE, parseRecordId} from "./validateTrainingRecord";

const COMPLETIONS: readonly MarkedCompletion[] = ["REALIZADO", "NAO_REALIZADO"];

/** Deduz a situação do treino pelas marcações (o app não envia a
 * situação): todos realizados, REALIZADO; parte, PARCIAL; nenhum,
 * NAO_REALIZADO.
 * @param {MarkedCompletion[]} marks Situação de cada exercício.
 * @return {ReportedRecordStatus} Situação do treino.
 */
export function deriveStatus(
  marks: MarkedCompletion[]
): ReportedRecordStatus {
  const done = marks.filter((mark) => mark === "REALIZADO").length;
  if (done === marks.length) return "REALIZADO";
  return done === 0 ? "NAO_REALIZADO" : "PARCIAL";
}

/** Valida a marcação de um exercício, na posição informada.
 * @param {unknown} value Item recebido.
 * @param {number} position Posição no treino (a partir de 1).
 * @return {ExecutionMark} Marcação normalizada.
 */
function parseMark(value: unknown, position: number): ExecutionMark {
  const label = `Exercício ${position}`;
  const item = asRecord(value, `${label}: dados inválidos.`);
  assertAllowedFields(item, ["codigo", "realizacao", "observacao"]);
  const codigo = parseCode(item.codigo, `${label}: código inválido.`);
  const realizacao = item.realizacao as MarkedCompletion;
  if (!COMPLETIONS.includes(realizacao)) {
    throw invalid(
      `${label}: a situação deve ser REALIZADO ou NAO_REALIZADO.`
    );
  }
  const observacao = parseOptionalText(
    item.observacao,
    MAX_EXERCISE_NOTE_LENGTH,
    `${label}: a observação deve ter até ${MAX_EXERCISE_NOTE_LENGTH} ` +
      "caracteres."
  );
  return {codigo, realizacao, ...(observacao && {observacao})};
}

/** Valida um inteiro dentro dos limites.
 * @param {unknown} value Valor recebido.
 * @param {number} min Valor mínimo.
 * @param {number} max Valor máximo.
 * @param {string} message Mensagem do erro.
 * @return {number} Valor validado.
 */
function parseInteger(
  value: unknown,
  min: number,
  max: number,
  message: string
): number {
  if (
    typeof value !== "number" ||
    !Number.isInteger(value) ||
    value < min ||
    value > max
  ) {
    throw invalid(message);
  }
  return value;
}

const isPresent = (value: unknown): boolean =>
  value !== undefined && value !== null;

/** Valida o envio da execução. A situação sai das marcações, e os campos
 * exigidos dependem dela: com algum exercício realizado, duração efetiva e
 * percepção são obrigatórias; sem nenhum, o treino não tem duração,
 * percepção nem dificuldades.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {ExecutionInput} Execução normalizada.
 */
export function validateExecution(data: unknown): ExecutionInput {
  const record = asRecord(data ?? {}, INVALID_DATA_MESSAGE);
  assertAllowedFields(record, [
    "registroId",
    "exercicios",
    "duracaoEfetiva",
    "percepcaoDesempenho",
    "dificuldades",
    "observacoes",
  ]);
  const registroId = parseRecordId(record.registroId);

  const list = record.exercicios;
  if (
    !Array.isArray(list) ||
    list.length === 0 ||
    list.length > MAX_SELECTED_EXERCISES
  ) {
    throw invalid("Informe a situação de cada exercício do treino.");
  }
  const exercicios = list.map((item, index) => parseMark(item, index + 1));
  const status = deriveStatus(exercicios.map((mark) => mark.realizacao));
  const observacoes = parseTextList(
    record.observacoes,
    "Observações",
    "Cada observação deve ter até 500 caracteres."
  );
  // Texto em branco conta como ausente, também no treino não realizado.
  const dificuldades = parseOptionalText(
    record.dificuldades,
    MAX_DIFFICULTIES_LENGTH,
    `As dificuldades devem ter até ${MAX_DIFFICULTIES_LENGTH} caracteres.`
  );

  if (status === "NAO_REALIZADO") {
    if (
      isPresent(record.duracaoEfetiva) ||
      isPresent(record.percepcaoDesempenho) ||
      dificuldades !== undefined
    ) {
      throw invalid(
        "Um treino não realizado não tem duração efetiva, percepção de " +
          "desempenho nem dificuldades."
      );
    }
    return {registroId, exercicios, status, observacoes};
  }

  const duracaoEfetiva = parseInteger(
    record.duracaoEfetiva,
    1,
    MAX_EFFECTIVE_MINUTES,
    "A duração efetiva deve ser um número inteiro de 1 a " +
      `${MAX_EFFECTIVE_MINUTES} minutos.`
  );
  const percepcaoDesempenho = parseInteger(
    record.percepcaoDesempenho,
    MIN_PERCEPTION,
    MAX_PERCEPTION,
    "A percepção de desempenho deve ser um número inteiro de " +
      `${MIN_PERCEPTION} a ${MAX_PERCEPTION}.`
  );
  return {
    registroId,
    exercicios,
    status,
    duracaoEfetiva,
    percepcaoDesempenho,
    ...(dificuldades && {dificuldades}),
    observacoes,
  };
}
