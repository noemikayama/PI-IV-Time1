// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
} from "../../../shared/utils/dates";
import type {DatePeriod} from "../../../shared/utils/dates";
import type {DashboardPeriodo} from "../types";

// Todas as janelas terminam no fim do dia de hoje (fuso de São Paulo) e
// começam no início do dia inicial, então o dia de hoje sempre entra inteiro
// e nenhum treino do futuro é contado. SEMPRE não tem início.
const WINDOW_START: Record<
    Exclude<DashboardPeriodo, "SEMPRE">,
    (today: Date) => Date
> = {
  DIARIO: (today) => today,
  SEMANAL: (today) => addDays(today, -6),
  MENSAL: (today) => addMonths(today, -1),
  SEMESTRAL: (today) => addMonths(today, -6),
  ANUAL: (today) => addMonths(today, -12),
};

// 'range' nulo dispensa o filtro de data na consulta (desde sempre).
export type DashboardWindow = {
    range: DatePeriod | null;
    inicio: string | null;
    fim: string;
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
  const fim = getTodayYmd(now);
  if (periodo === "SEMPRE") {
    return {range: null, inicio: null, fim};
  }

  const today = getDayStart(now);
  const start = WINDOW_START[periodo](today);
  return {
    range: {start, end: addDays(today, 1)},
    inicio: toYmd(start),
    fim,
  };
}
