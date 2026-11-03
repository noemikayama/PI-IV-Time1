// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do modo painel profissional do treinador e
// mensagem própria para dados que não são um objeto de filtros.
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação dos filtros de período e de cavalo do dashboard.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import type {DashboardFiltros, DashboardPeriodo} from "../types";

const PERIODOS: readonly DashboardPeriodo[] = [
  "SEMPRE",
  "DIARIO",
  "SEMANAL",
  "MENSAL",
  "SEMESTRAL",
  "ANUAL",
];

const ALLOWED_FIELDS: readonly string[] = [
  "periodo",
  "cavaloId",
  "painelProfissional",
];

/** Cria um erro de argumento inválido com a mensagem informada.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro de argumento inválido.
 */
function invalid(message: string): AppError {
  return new AppError("invalid-argument", message);
}

/** Recusa campos fora dos filtros aceitos, para que um nome errado não
 * passe despercebido como "sem filtro".
 * @param {Object} data Dados recebidos.
 */
function assertOnlyFilters(data: Record<string, unknown>): void {
  const unknownField = Object.keys(data).find(
    (field) => !ALLOWED_FIELDS.includes(field)
  );
  if (unknownField !== undefined) {
    throw invalid(`O filtro '${unknownField}' não existe.`);
  }
}

/** Valida o período; ausente equivale a "desde sempre".
 * @param {unknown} value Valor recebido.
 * @return {DashboardPeriodo} Período validado.
 */
function parsePeriodo(value: unknown): DashboardPeriodo {
  if (value === undefined || value === null) return "SEMPRE";
  if (!PERIODOS.includes(value as DashboardPeriodo)) {
    throw invalid(`Período inválido. Use ${PERIODOS.join(", ")}.`);
  }
  return value as DashboardPeriodo;
}

/** Valida o cavalo do filtro; ausente equivale a todos os cavalos.
 * @param {unknown} value Valor recebido.
 * @return {ObjectId|null} _id do cavalo ou null.
 */
function parseCavaloId(value: unknown): ObjectId | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== "string" || !/^[0-9a-f]{24}$/i.test(value)) {
    throw invalid("Cavalo inválido.");
  }
  return new ObjectId(value);
}

/** Valida o modo do treinador; ausente equivale ao painel desativado
 * (visão dos cavalos).
 * @param {unknown} value Valor recebido.
 * @return {boolean} true para o painel profissional.
 */
function parsePainelProfissional(value: unknown): boolean {
  if (value === undefined || value === null) return false;
  if (typeof value !== "boolean") {
    throw invalid("O painel profissional deve ser true ou false.");
  }
  return value;
}

/** Valida os filtros do dashboard. Sem dados, assume o padrão da tela:
 * todos os cavalos, desde sempre e painel profissional desativado.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {DashboardFiltros} Filtros validados.
 */
export function validateDashboardFilters(data: unknown): DashboardFiltros {
  const value = data ?? {};
  if (typeof value !== "object" || Array.isArray(value)) {
    throw invalid("Filtros do dashboard inválidos.");
  }
  const record = value as Record<string, unknown>;
  assertOnlyFilters(record);

  // As regras de cada perfil sobre o painel ficam nos services.
  return {
    periodo: parsePeriodo(record.periodo),
    cavaloId: parseCavaloId(record.cavaloId),
    painelProfissional: parsePainelProfissional(record.painelProfissional),
  };
}
