// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Limites em instantes de São Paulo para os campos com hora e
// fim em hoje também em SEMPRE (treinos futuros não contam como previstos).
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conversão do filtro de período em um intervalo de datas.
// -----------------------------------------------------------------------------

import {
  addDays,
  addMonths,
  getDayStart,
  getTodayYmd,
  toYmd,
  toZonedDayStart,
} from "../../../shared/utils/dates";
import type {DashboardPeriodo, DashboardWindow} from "../types";

// Todas as janelas terminam no fim do dia de hoje (fuso de São Paulo) e
// começam no início do dia inicial, então o dia de hoje sempre entra inteiro
// e nenhum treino do futuro é contado. SEMPRE não tem início: começa na
// época Unix, anterior a qualquer dado do sistema.
const WINDOW_START: Record<DashboardPeriodo, (today: Date) => Date> = {
  SEMPRE: () => new Date(0),
  DIARIO: (today) => today,
  SEMANAL: (today) => addDays(today, -6),
  MENSAL: (today) => addMonths(today, -1),
  SEMESTRAL: (today) => addMonths(today, -6),
  ANUAL: (today) => addMonths(today, -12),
};

/** Converte o período do filtro no intervalo usado nas consultas.
 * @param {DashboardPeriodo} periodo Período escolhido.
 * @param {Date} now Data usada como referência.
 * @return {DashboardWindow} Intervalo e limites em AAAA-MM-DD.
 */
export function resolveDashboardWindow(
  periodo: DashboardPeriodo,
  now = new Date()
): DashboardWindow {
  const today = getDayStart(now);
  const start = WINDOW_START[periodo](today);
  const end = addDays(today, 1);
  return {
    range: {start, end},
    instants: {start: toZonedDayStart(start), end: toZonedDayStart(end)},
    inicio: periodo === "SEMPRE" ? null : toYmd(start),
    fim: getTodayYmd(now),
  };
}
