// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Início do dia, soma de dias e de meses e data em AAAA-MM-DD,
// usados pelos períodos do dashboard.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Data de hoje em AAAA-MM-DD e validação de datas do calendário.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação dos períodos (dia, semana e mês) usados na home.
// -----------------------------------------------------------------------------

const TIME_ZONE = "America/Sao_Paulo";
const DAY_MS = 86_400_000;

// 'start' é inclusivo e 'end' é exclusivo.
export type DatePeriod = {start: Date; end: Date};

export const addDays = (date: Date, days: number) =>
  new Date(date.getTime() + days * DAY_MS);

// Datas de calendário (dataPlanejada, dataExecucao) são gravadas à meia-noite
// UTC, então a conversão para AAAA-MM-DD é direta.
export const toYmd = (date: Date): string => date.toISOString().slice(0, 10);

/** Retorna a data de hoje (AAAA-MM-DD) no fuso de São Paulo.
 * @param {Date} now Data usada como referência.
 * @return {string} Data no formato AAAA-MM-DD.
 */
export function getTodayYmd(now = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", {timeZone: TIME_ZONE}).format(now);
}

/** Retorna o início do dia de hoje no fuso de São Paulo.
 * @param {Date} now Data usada como referência.
 * @return {Date} Meia-noite do dia corrente.
 */
export function getDayStart(now = new Date()): Date {
  return new Date(`${getTodayYmd(now)}T00:00:00.000Z`);
}

/** Soma meses a uma data, sem estourar para o mês seguinte: um dia que não
 * existe no mês de destino cai no último dia dele (31/03 - 1 mês = 28/02).
 * @param {Date} date Data de origem.
 * @param {number} months Meses somados (negativo para subtrair).
 * @return {Date} Data deslocada.
 */
export function addMonths(date: Date, months: number): Date {
  const year = date.getUTCFullYear();
  const month = date.getUTCMonth() + months;
  const lastDay = new Date(Date.UTC(year, month + 1, 0)).getUTCDate();
  return new Date(
    Date.UTC(year, month, Math.min(date.getUTCDate(), lastDay))
  );
}

/** Confere se o texto é uma data AAAA-MM-DD existente no calendário.
 * @param {string} value Texto recebido.
 * @return {boolean} true se a data existe (rejeita 2026-02-30, por exemplo).
 */
export function isValidYmd(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const date = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(date.getTime()) &&
    date.toISOString().startsWith(value);
}

/** Retorna os períodos de dia, semana e mês no fuso de São Paulo.
 * @param {Date} now Data usada como referência.
 * @return {Object} Períodos do dia, semana e mês.
 */
export function getPeriods(now = new Date()) {
  const today = getDayStart(now);
  const monday = addDays(today, -((today.getUTCDay() + 6) % 7));
  const year = today.getUTCFullYear();
  const month = today.getUTCMonth();

  return {
    day: {start: today, end: addDays(today, 1)} as DatePeriod,
    week: {start: monday, end: addDays(monday, 7)} as DatePeriod,
    month: {
      start: new Date(Date.UTC(year, month, 1)),
      end: new Date(Date.UTC(year, month + 1, 1)),
    } as DatePeriod,
  };
}
