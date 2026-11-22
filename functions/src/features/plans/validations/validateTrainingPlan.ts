// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do plano pedido na visualização e no cancelamento.
// Alteração: Validação da edição do plano, com os campos do cadastro.
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do cadastro de plano, do seletor de avaliações e da
// galeria de treinamentos.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {
  addMonths,
  getTodayYmd,
  isValidYmd,
} from "../../../shared/utils/dates";
import {asRecord, assertAllowedFields} from "../../authentication/shared";
import {parseBusca, parseObjectId} from "../../exercises";
import {DIAS_SEMANA} from "../types";
import type {
  PlanIdInput,
  TrainingGalleryInput,
  TrainingPlanInput,
  TrainingPlanUpdateInput,
  TrainingsByDay,
} from "../types";

const MAX_TITLE_LENGTH = 80;
const MAX_GOAL_LENGTH = 1000;
// Duração máxima do plano: limita os registros gerados em uma transação.
const MAX_PLAN_MONTHS = 12;

const PLAN_FIELDS = [
  "titulo",
  "objetivo",
  "cavaloId",
  "avaliacaoId",
  "dataInicio",
  "dataFim",
  "treinosPorDia",
] as const;

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

/** _id opcional: ausente, nulo ou vazio vira null.
 * @param {unknown} value Valor recebido.
 * @param {string} message Mensagem usada se o valor for inválido.
 * @return {ObjectId|null} _id convertido, ou null.
 */
function parseOptionalId(value: unknown, message: string): ObjectId | null {
  if (value === undefined || value === null || value === "") return null;
  return parseObjectId(value, message);
}

/** Valida uma data AAAA-MM-DD existente no calendário.
 * @param {unknown} value Valor recebido.
 * @param {string} label Nome do campo usado na mensagem.
 * @return {string} Data validada.
 */
function parseYmd(value: unknown, label: string): string {
  if (typeof value !== "string" || !isValidYmd(value)) {
    throw invalid(`${label} inválida. Use o formato AAAA-MM-DD.`);
  }
  return value;
}

export const START_IN_PAST_MESSAGE =
  "A data de início deve ser hoje ou uma data futura.";

/** Valida o período: fim a partir do início e duração de no máximo
 * MAX_PLAN_MONTHS meses. No cadastro, o início também precisa ser hoje ou
 * no futuro (fuso de São Paulo); na edição, isso depende de o plano já ter
 * começado e é conferido no service.
 * @param {unknown} inicio dataInicio recebida.
 * @param {unknown} fim dataFim recebida.
 * @param {boolean} futureStart Se o início precisa ser hoje ou depois.
 * @return {Object} Datas validadas.
 */
function parsePeriod(
  inicio: unknown,
  fim: unknown,
  futureStart: boolean
): {dataInicio: string; dataFim: string} {
  const dataInicio = parseYmd(inicio, "Data de início");
  const dataFim = parseYmd(fim, "Data de fim");
  // Datas AAAA-MM-DD são comparáveis como texto.
  if (futureStart && dataInicio < getTodayYmd()) {
    throw invalid(START_IN_PAST_MESSAGE);
  }
  if (dataFim < dataInicio) {
    throw invalid("A data de fim não pode ser anterior à data de início.");
  }
  const limit = addMonths(
    new Date(`${dataInicio}T00:00:00.000Z`),
    MAX_PLAN_MONTHS
  );
  if (new Date(`${dataFim}T00:00:00.000Z`) >= limit) {
    throw invalid(`O plano pode durar no máximo ${MAX_PLAN_MONTHS} meses.`);
  }
  return {dataInicio, dataFim};
}

/** Valida o treino de cada dia (id ou null). Dias ausentes ficam vazios;
 * pelo menos um dia precisa de treino.
 * @param {unknown} value Valor recebido.
 * @return {TrainingsByDay} Treino de cada dia.
 */
function parseTrainingsByDay(value: unknown): TrainingsByDay {
  const record = asRecord(value, "Treinos por dia inválidos.");
  assertAllowedFields(record, DIAS_SEMANA);
  const byDay = Object.fromEntries(
    DIAS_SEMANA.map((dia) => [
      dia,
      parseOptionalId(record[dia], `Treino inválido em ${dia}.`),
    ])
  ) as TrainingsByDay;
  if (DIAS_SEMANA.every((dia) => byDay[dia] === null)) {
    throw invalid("Escolha um treino para pelo menos um dia da semana.");
  }
  return byDay;
}

/** Campos do plano, iguais no cadastro e na edição.
 * @param {Record<string, unknown>} record Dados recebidos.
 * @param {boolean} futureStart Se o início precisa ser hoje ou depois.
 * @return {TrainingPlanInput} Dados validados e normalizados.
 */
function parsePlanFields(
  record: Record<string, unknown>,
  futureStart: boolean
): TrainingPlanInput {
  return {
    titulo: parseText(record.titulo, "O título", 3, MAX_TITLE_LENGTH),
    objetivo: parseText(record.objetivo, "O objetivo", 1, MAX_GOAL_LENGTH),
    cavaloId: parseObjectId(record.cavaloId, "Cavalo inválido."),
    avaliacaoId: parseOptionalId(record.avaliacaoId, "Avaliação inválida."),
    ...parsePeriod(record.dataInicio, record.dataFim, futureStart),
    treinosPorDia: parseTrainingsByDay(record.treinosPorDia),
  };
}

/** Valida e normaliza os dados do cadastro de plano.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {TrainingPlanInput} Dados validados e normalizados.
 */
export function validateTrainingPlan(data: unknown): TrainingPlanInput {
  const record = asRecord(data);
  assertAllowedFields(record, PLAN_FIELDS);
  return parsePlanFields(record, true);
}

/** Valida a edição: o estado final da tela, com os mesmos campos e regras
 * do cadastro, mais o plano editado.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {TrainingPlanUpdateInput} Dados validados e normalizados.
 */
export function validateTrainingPlanUpdate(
  data: unknown
): TrainingPlanUpdateInput {
  const record = asRecord(data);
  assertAllowedFields(record, [...PLAN_FIELDS, "planoId"]);
  return {
    planoId: parseObjectId(record.planoId, "Plano inválido."),
    ...parsePlanFields(record, false),
  };
}

/** Valida o pedido das avaliações de um cavalo.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {ObjectId} _id do cavalo.
 */
export function validateHorseEvaluationsQuery(data: unknown): ObjectId {
  const record = asRecord(data ?? {}, "Dados da consulta inválidos.");
  assertAllowedFields(record, ["cavaloId"]);
  return parseObjectId(record.cavaloId, "Cavalo inválido.");
}

/** Valida os filtros da galeria: cavalo obrigatório e busca opcional.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {TrainingGalleryInput} Filtros validados.
 */
export function validateTrainingGallery(data: unknown): TrainingGalleryInput {
  const record = asRecord(data ?? {}, "Dados da consulta inválidos.");
  assertAllowedFields(record, ["cavaloId", "busca"]);
  const busca = parseBusca(record.busca);
  return {
    cavaloId: parseObjectId(record.cavaloId, "Cavalo inválido."),
    ...(busca && {busca}),
  };
}

/** Valida o plano pedido (visualização e cancelamento).
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {PlanIdInput} _id do plano.
 */
export function validatePlanId(data: unknown): PlanIdInput {
  const record = asRecord(data ?? {}, "Dados da consulta inválidos.");
  assertAllowedFields(record, ["planoId"]);
  return {planoId: parseObjectId(record.planoId, "Plano inválido.")};
}
