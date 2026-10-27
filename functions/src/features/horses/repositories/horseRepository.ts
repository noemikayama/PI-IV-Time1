// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta dos treinadores dos cavalos para a home.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import type {HorseTrainerRef} from "../types/horse";

/** Lista os treinadores dos cavalos, em ordem alfabética.
 * @param {ObjectId[]} horseIds IDs dos cavalos.
 * @param {number} limit Quantidade máxima de treinadores.
 */
export async function findTrainersOfHorses(
  horseIds: ObjectId[],
  limit: number
): Promise<HorseTrainerRef[]> {
  if (horseIds.length === 0) return [];

  const db = await getDatabase();
  return db
    .collection(COLLECTIONS.Cavalos)
    .aggregate<HorseTrainerRef>([
      {$match: {_id: {$in: horseIds}}},
      {$unwind: "$treinadores"},
      {
        $group: {
          _id: "$treinadores._id",
          nome: {$first: "$treinadores.nome"},
        },
      },
      {$sort: {nome: 1}},
      {$limit: limit},
    ])
    .toArray();
}
