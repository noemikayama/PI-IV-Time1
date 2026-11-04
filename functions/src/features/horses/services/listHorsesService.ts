// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Lista de cavalos do responsável e do treinador.
// Alteração: Busca por nome do cavalo (RF04014), combinada à ordenação.
// Alteração: HorseListSource importado de types.
// -----------------------------------------------------------------------------

import {ROLES} from "../../../shared/constants/roles";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import {
  findGuardianListHorses,
  findTrainerListHorses,
} from "../repositories/horseRepository";
import type {
  HorseListInput,
  HorseListOrder,
  HorseListResult,
  HorseListSource,
} from "../types";
import {assertActiveAccount} from "./horseAccess";
import {toGuardianHorseCard, toTrainerHorseCard} from "./horseMappers";

const collator = new Intl.Collator("pt-BR", {
  sensitivity: "base",
  numeric: true,
});

type SortableCard = {id: string; nome: string; vinculadoEm: string};

/** Normaliza o texto para a busca: sem acentos e sem diferença de caixa.
 * @param {string} text Texto original.
 * @return {string} Texto normalizado.
 */
function normalizeForSearch(text: string): string {
  return text
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .toLocaleLowerCase("pt-BR");
}

/** Mantém os cavalos cujo nome contém o texto buscado ("tro" encontra
 * "Trovão"). Roda antes de montar os cards, então só os encontrados ganham
 * URL de foto.
 * @param {HorseListSource[]} horses Cavalos do usuário.
 * @param {string|undefined} busca Texto buscado.
 * @return {HorseListSource[]} Cavalos encontrados.
 */
function filterByName(
  horses: HorseListSource[],
  busca: string | undefined
): HorseListSource[] {
  if (!busca) return horses;
  const term = normalizeForSearch(busca);
  return horses.filter((horse) =>
    normalizeForSearch(horse.nome).includes(term)
  );
}

/** Ordena os cards. Empates de nome desempatam pelo id; empates de data,
 * pelo nome. vinculadoEm é ISO em UTC, então a ordem do texto é a da data.
 * @param {Array} cards Cards da lista.
 * @param {HorseListOrder} order Ordenação pedida.
 * @return {Array} Cards ordenados.
 */
function sortCards<T extends SortableCard>(
  cards: T[],
  order: HorseListOrder
): T[] {
  const byName = (a: T, b: T) =>
    collator.compare(a.nome, b.nome) || a.id.localeCompare(b.id);
  const byDate = (a: T, b: T) =>
    a.vinculadoEm.localeCompare(b.vinculadoEm) || byName(a, b);

  const compare = {
    A_Z: byName,
    Z_A: (a: T, b: T) => byName(b, a),
    MAIS_RECENTES: (a: T, b: T) =>
      b.vinculadoEm.localeCompare(a.vinculadoEm) || byName(a, b),
    MAIS_ANTIGOS: byDate,
  }[order];
  return [...cards].sort(compare);
}

/** Lista os cavalos ativos do usuário a partir da coleção de origem
 * ('cavalos'), então um vínculo desfeito some da lista na hora (RF04016).
 * Responsável vê os cavalos em que é proprietário ou atleta; treinador, os
 * que acompanha. A busca por nome e a ordenação valem juntas.
 * @param {AuthenticatedUser} user Usuário autenticado.
 * @param {HorseListInput} input Ordenação e busca validadas.
 * @return {Promise<HorseListResult>} Cards no formato do perfil.
 */
export async function listHorsesService(
  user: AuthenticatedUser,
  input: HorseListInput
): Promise<HorseListResult> {
  const {uid, role} = user;
  // Recusa conta inativa e qualquer papel que não seja responsável ou
  // treinador.
  await assertActiveAccount(uid, role);

  if (role === ROLES.trainer) {
    const horses = filterByName(await findTrainerListHorses(uid), input.busca);
    const cards = await Promise.all(
      horses.map((horse) => toTrainerHorseCard(horse, uid))
    );
    return {tipoConta: "TREINADOR", cavalos: sortCards(cards, input.ordenacao)};
  }

  const horses = filterByName(await findGuardianListHorses(uid), input.busca);
  const cards = await Promise.all(
    horses.map((horse) => toGuardianHorseCard(horse, uid))
  );
  return {tipoConta: "RESPONSAVEL", cavalos: sortCards(cards, input.ordenacao)};
}
