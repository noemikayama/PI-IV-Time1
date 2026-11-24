// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do dia que escolhe a semana da agenda.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {getDayStart, isValidYmd} from "../../../shared/utils/dates";
import type {AgendaFiltro} from "../types";

/** Valida a entrada da agenda. Sem 'data', usa hoje (fuso de São Paulo),
 * que é a semana mostrada ao abrir a tela.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @param {Date} now Momento usado para definir hoje.
 * @return {AgendaFiltro} Dia já convertido para meia-noite UTC.
 */
export function validateAgendaInput(
  data: unknown,
  now = new Date()
): AgendaFiltro {
  const value = data ?? {};
  if (typeof value !== "object" || Array.isArray(value)) {
    throw new AppError("invalid-argument", "Dados da agenda inválidos.");
  }
  const record = value as Record<string, unknown>;

  // Um nome errado ('dia' em vez de 'data') não passa como "hoje".
  const unknownField = Object.keys(record).find((field) => field !== "data");
  if (unknownField !== undefined) {
    throw new AppError(
      "invalid-argument",
      `O campo '${unknownField}' não existe.`
    );
  }

  const day = record.data;
  if (day === undefined || day === null) return {data: getDayStart(now)};
  if (typeof day !== "string" || !isValidYmd(day)) {
    throw new AppError("invalid-argument", "Data inválida. Use AAAA-MM-DD.");
  }
  return {data: new Date(`${day}T00:00:00.000Z`)};
}
