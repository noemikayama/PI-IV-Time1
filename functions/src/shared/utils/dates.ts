// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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

/** Retorna os períodos de dia, semana e mês no fuso de São Paulo.
 * @param {Date} now Data usada como referência.
 * @return {Object} Períodos do dia, semana e mês.
 */
export function getPeriods(now = new Date()) {
  const ymd = new Intl.DateTimeFormat("en-CA", {timeZone: TIME_ZONE})
    .format(now); // AAAA-MM-DD
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
