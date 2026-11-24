// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Carga dos exercícios selecionados pelo treinador, usada pelo
// tempo total e pelo cadastro de treinamentos.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {findTrainerExercisesByIds} from "../repositories/exerciseRepository";
import type {ExerciseDocument} from "../types";

/** Carrega os exercícios selecionados, na ordem recebida (que é a ordem de
 * execução no treinamento). Todos precisam estar ativos e ter sido
 * cadastrados pelo treinador; genéricos e específicos de cavalos diferentes
 * podem ser misturados. Um _id repetido devolve o exercício repetido.
 * @param {string} uid UID do treinador autenticado.
 * @param {ObjectId[]} ids _id dos exercícios selecionados.
 * @return {Promise<ExerciseDocument[]>} Exercícios, na ordem de 'ids'.
 */
export async function loadTrainerExercises(
  uid: string,
  ids: ObjectId[]
): Promise<ExerciseDocument[]> {
  const unique = [...new Map(ids.map((id) => [id.toHexString(), id]))];
  const found = await findTrainerExercisesByIds(
    uid,
    unique.map(([, id]) => id)
  );
  const byId = new Map(found.map((exercise) => [
    exercise._id.toHexString(),
    exercise,
  ]));

  // A mensagem não diferencia exercício inexistente de exercício de outro
  // treinador, para não revelar o que existe no acervo alheio.
  const missing = unique
    .map(([hex]) => hex)
    .filter((hex) => !byId.has(hex));
  if (missing.length > 0) {
    throw new AppError(
      "not-found",
      `Exercício não encontrado entre os seus: ${missing.join(", ")}.`
    );
  }
  return ids.map((id) => byId.get(id.toHexString()) as ExerciseDocument);
}
