// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conversão de um dia de calendário no instante em que ele
// começa em São Paulo e filtro de período para consultas, usados pelo
// dashboard.
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

// Reutilizado entre chamadas: criar um Intl.DateTimeFormat é caro.
const OFFSET_FORMAT = new Intl.DateTimeFormat("en-US", {
  timeZone: TIME_ZONE,
  timeZoneName: "longOffset",
});

/** Monta o filtro de um campo de data dentro do período, para o $match.
 * @param {string} field Campo de data.
 * @param {DatePeriod} period Período do filtro.
 * @return {Object} Trecho do filtro.
 */
export const inPeriod = (field: string, period: DatePeriod) => ({
  [field]: {$gte: period.start, $lt: period.end},
});

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

/** Converte um dia de calendário (meia-noite UTC) no instante em que ele
 * começa em São Paulo. Campos com hora ('criadoEm', 'feedback.data') são
 * instantes, então o dia 28 vai de 28T03:00Z a 29T03:00Z, e não de 28T00:00Z.
 * @param {Date} day Dia de calendário à meia-noite UTC.
 * @return {Date} Início do dia no fuso de São Paulo.
 */
export function toZonedDayStart(day: Date): Date {
  // O offset é lido ao meio-dia para não cair na virada do dia anterior.
  const offset = OFFSET_FORMAT
    .formatToParts(new Date(day.getTime() + DAY_MS / 2))
    .find((part) => part.type === "timeZoneName")?.value ?? "GMT";
  // "GMT-03:00" -> -180 minutos; "GMT" sozinho é offset zero.
  const match = /GMT([+-])(\d{2}):(\d{2})/.exec(offset);
  const minutes = match ?
    (match[1] === "-" ? -1 : 1) * (Number(match[2]) * 60 + Number(match[3])) :
    0;
  return new Date(day.getTime() - minutes * 60_000);
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
