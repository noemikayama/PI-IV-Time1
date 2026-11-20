// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Regra única de quem vê o exercício (autor ou vinculado a um
// cavalo dele), usada pela consulta e pela edição.
// -----------------------------------------------------------------------------

import {findLinkedHorseIds} from "../../horses";
import {
  isExercisePlannedForHorses,
} from "../repositories/exerciseUsageRepository";
import type {
  AuthoredExercise,
  ExerciseAccess,
  ExerciseDocument,
} from "../types";

/** Diz se o exercício tem autor, isto é, se foi cadastrado por um treinador.
 * Os da plataforma não têm, não entram em treinamentos e não são mostrados
 * a ninguém.
 * @param {ExerciseDocument} exercise Exercício lido do banco.
 * @return {boolean} Se o exercício tem autor.
 */
export function hasAuthor(
  exercise: ExerciseDocument
): exercise is AuthoredExercise {
  // Também null: exercícios importados podem gravar o autor ausente assim.
  return exercise.treinador !== undefined && exercise.treinador !== null;
}

/** Decide quem vê o exercício. O autor vê sempre, mesmo sem vínculo com o
 * cavalo do exercício. Os demais precisam de vínculo, hoje, com um cavalo
 * ativo do exercício: o cavalo do específico, ou um cavalo cujo plano ou
 * registro de treino usa o exercício. Quem só chega pelo plano não vê o
 * cavalo de um exercício que mudou de cavalo depois de planejado. As
 * consultas só rodam quando são necessárias.
 * @param {ExerciseDocument} exercise Exercício ativo lido do banco.
 * @param {string} uid UID de quem consulta.
 * @return {Promise<ExerciseAccess|null>} Relação com o exercício, ou null
 *   para quem não pode vê-lo.
 */
export async function resolveExerciseAccess(
  exercise: ExerciseDocument,
  uid: string
): Promise<ExerciseAccess | null> {
  if (!hasAuthor(exercise)) return null;
  if (exercise.treinador._id === uid) {
    return {isAuthor: true, showHorse: true};
  }

  const horseIds = await findLinkedHorseIds(uid);
  if (horseIds.length === 0) return null;

  const horseId = exercise.privacidade === "ESPECIFICO" ?
    exercise.cavalo?._id :
    undefined;
  if (horseId && horseIds.some((id) => id.equals(horseId))) {
    return {isAuthor: false, showHorse: true};
  }

  const planned = await isExercisePlannedForHorses(exercise._id, horseIds);
  return planned ? {isAuthor: false, showHorse: false} : null;
}
