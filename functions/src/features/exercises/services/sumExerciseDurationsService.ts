// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tempo total dos exercícios selecionados no treinamento.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {assertActiveAccount} from "../../horses";
import type {ExerciseDurationSumResult} from "../types";
import {loadTrainerExercises} from "./trainerExercises";

/** Soma a duração padrão dos exercícios selecionados. É só informativo: a
 * duração estimada do treinamento pode ser diferente (descansos,
 * deslocamentos), e o cadastro não a compara com esta soma.
 * @param {string} uid UID do treinador autenticado.
 * @param {ObjectId[]} ids _id dos exercícios selecionados.
 * @return {Promise<ExerciseDurationSumResult>} Soma, em minutos.
 */
export async function sumExerciseDurationsService(
  uid: string,
  ids: ObjectId[]
): Promise<ExerciseDurationSumResult> {
  await assertActiveAccount(uid, ROLES.trainer);
  const exercises = await loadTrainerExercises(uid, ids);
  return {
    duracaoTotalMinutos: exercises.reduce(
      (total, exercise) => total + exercise.duracaoPadraoMinutos,
      0
    ),
  };
}
