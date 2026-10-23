// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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

const addDays = (date: Date, days: number) =>
  new Date(date.getTime() + days * DAY_MS);

/** Retorna a data de hoje (AAAA-MM-DD) no fuso de São Paulo.
 * @param {Date} now Data usada como referência.
 * @return {string} Data no formato AAAA-MM-DD.
 */
export function getTodayYmd(now = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", {timeZone: TIME_ZONE}).format(now);
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
  const ymd = getTodayYmd(now);
  const today = new Date(`${ymd}T00:00:00.000Z`);
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
