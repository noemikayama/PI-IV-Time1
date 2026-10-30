// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação dos filtros de período e de cavalo do dashboard.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {asRecord} from "../../authentication/shared";
import type {DashboardFiltros, DashboardPeriodo} from "../types";

const PERIODOS: readonly DashboardPeriodo[] = [
  "SEMPRE",
  "DIARIO",
  "SEMANAL",
  "MENSAL",
  "SEMESTRAL",
  "ANUAL",
];

const ALLOWED_FIELDS: readonly string[] = ["periodo", "cavaloId"];

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

/** Valida os filtros do dashboard. Sem dados, assume o padrão da tela:
 * todos os cavalos e desde sempre.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {DashboardFiltros} Filtros validados.
 */
export function validateDashboardFilters(data: unknown): DashboardFiltros {
  const record = asRecord(data ?? {});
  assertOnlyFilters(record);

  return {
    periodo: parsePeriodo(record.periodo),
    cavaloId: parseCavaloId(record.cavaloId),
  };
}
