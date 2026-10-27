// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cálculo da idade do cavalo a partir da data de nascimento.
// -----------------------------------------------------------------------------

import {getTodayYmd} from "../../../shared/utils/dates";
import type {HorseAge} from "../types";

/** Calcula a idade em anos e meses completos (fuso de São Paulo).
 * Ex.: nascido em 2016-04-10, em 2026-10-22 tem 10 anos e 6 meses.
 * @param {string} dataNascimento Data de nascimento (AAAA-MM-DD).
 * @param {string} today Data de referência (AAAA-MM-DD).
 * @return {HorseAge} Idade calculada.
 */
export function calculateHorseAge(
  dataNascimento: string,
  today = getTodayYmd()
): HorseAge {
  const [birthYear, birthMonth, birthDay] = dataNascimento
    .split("-")
    .map(Number);
  const [year, month, day] = today.split("-").map(Number);

  let months = (year - birthYear) * 12 + (month - birthMonth);
  // O mês só conta depois de completar o dia do nascimento.
  if (day < birthDay) months -= 1;
  months = Math.max(months, 0);

  return {anos: Math.floor(months / 12), meses: months % 12};
}
