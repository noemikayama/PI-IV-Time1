// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Filtro de cavalo e seletor "Todos" compartilhados pelos
// dashboards do responsável e do treinador.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import type {RefCavalo} from "../types";

// Resumo de cavalo das listas 'responsaveis.cavalos' e 'treinadores.cavalos'.
type HorseSummary = {_id: ObjectId; nome: string};

export type HorseScope = {
    selected: HorseSummary | null;
    horseIds: ObjectId[];
};

/** Resolve os cavalos consultados a partir da lista do próprio usuário,
 * então um cavalo de terceiros nunca entra nos números. Filtrar por um
 * cavalo fora da lista equivale a ele não existir.
 * @param {HorseSummary[]} horses Cavalos aos quais o usuário tem acesso.
 * @param {ObjectId} cavaloId Cavalo do filtro ou null (todos).
 * @return {HorseScope} Cavalo escolhido e _ids consultados.
 */
export function resolveHorseScope(
  horses: HorseSummary[],
  cavaloId: ObjectId | null
): HorseScope {
  if (!cavaloId) {
    return {selected: null, horseIds: horses.map((horse) => horse._id)};
  }

  const selected = horses.find((horse) => horse._id.equals(cavaloId));
  if (!selected) {
    throw new AppError("not-found", "Cavalo não encontrado.");
  }
  return {selected, horseIds: [selected._id]};
}

/** Lista completa do seletor "Todos", em ordem alfabética.
 * @param {HorseSummary[]} horses Cavalos aos quais o usuário tem acesso.
 * @return {RefCavalo[]} Opções do filtro.
 */
export const toHorseOptions = (horses: HorseSummary[]): RefCavalo[] =>
  horses
    .map((horse) => ({id: String(horse._id), nome: horse.nome}))
    .sort((a, b) => a.nome.localeCompare(b.nome, "pt-BR"));
