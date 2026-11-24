// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Busca por nome compartilhada pela lista de cavalos e pela
// galeria de exercícios (movida de listHorsesService).
// -----------------------------------------------------------------------------

/** Normaliza o texto para a busca: sem acentos e sem diferença de caixa.
 * @param {string} text Texto original.
 * @return {string} Texto normalizado.
 */
export function normalizeForSearch(text: string): string {
  return text
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .toLocaleLowerCase("pt-BR");
}

/** Mantém os itens cujo nome contém o texto buscado ("tro" encontra
 * "Trovão"). Sem busca, devolve a lista inteira.
 * @param {Array} items Itens com 'nome'.
 * @param {string|undefined} busca Texto buscado.
 * @return {Array} Itens encontrados.
 */
export function filterByName<T extends {nome: string}>(
  items: T[],
  busca: string | undefined
): T[] {
  if (!busca) return items;
  const term = normalizeForSearch(busca);
  return items.filter((item) => normalizeForSearch(item.nome).includes(term));
}
