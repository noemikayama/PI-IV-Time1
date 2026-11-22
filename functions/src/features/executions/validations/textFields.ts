// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Texto opcional e lista de textos, com os limites da execução e
// do feedback.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {MAX_TEXT_ITEM_LENGTH, MAX_TEXT_ITEMS} from "../constants/limits";

/** Cria o erro de validação exibido ao usuário.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro 'invalid-argument'.
 */
export const invalid = (message: string): AppError =>
  new AppError("invalid-argument", message);

/** Valida um texto opcional: tira os espaços das pontas, e vazio vira
 * ausente.
 * @param {unknown} value Valor recebido.
 * @param {number} max Tamanho máximo.
 * @param {string} message Mensagem para texto inválido ou longo demais.
 * @return {string|undefined} Texto normalizado, ou undefined.
 */
export function parseOptionalText(
  value: unknown,
  max: number,
  message: string
): string | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value !== "string") throw invalid(message);
  const text = value.trim();
  if (text.length > max) throw invalid(message);
  return text.length > 0 ? text : undefined;
}

/** Valida uma lista de textos (o app quebra o texto digitado em linhas).
 * Ausente ou null vira lista vazia. Linhas em branco são descartadas, e o
 * limite de itens vale para o que sobra.
 * @param {unknown} value Valor recebido.
 * @param {string} listLabel Nome da lista na mensagem ("Observações").
 * @param {string} itemMessage Mensagem para item que não é texto ou é
 * longo demais.
 * @return {string[]} Itens sem os espaços das pontas.
 */
export function parseTextList(
  value: unknown,
  listLabel: string,
  itemMessage: string
): string[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value)) {
    throw invalid(`${listLabel}: envie uma lista de textos.`);
  }
  const items = value.map((item) => {
    if (typeof item !== "string") throw invalid(itemMessage);
    const text = item.trim();
    if (text.length > MAX_TEXT_ITEM_LENGTH) throw invalid(itemMessage);
    return text;
  }).filter((text) => text.length > 0);
  if (items.length > MAX_TEXT_ITEMS) {
    throw invalid(`${listLabel}: informe no máximo ${MAX_TEXT_ITEMS} itens.`);
  }
  return items;
}
