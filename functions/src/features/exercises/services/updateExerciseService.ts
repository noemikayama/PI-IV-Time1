// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Edição do exercício pelo treinador que o cadastrou, inclusive
// tipo e cavalo.
// -----------------------------------------------------------------------------

import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {assertActiveAccount} from "../../horses";
import {
  findActiveExerciseById,
  updateAuthorExercise,
} from "../repositories/exerciseRepository";
import type {
  ExerciseHorseRef,
  ExerciseUpdateInput,
  ExerciseView,
} from "../types";
import {hasAuthor, resolveExerciseAccess} from "./exerciseAccess";
import {buildExerciseUpdate, planHorseChange} from "./exerciseUpdate";
import type {HorseChange} from "./exerciseUpdate";
import {buildExerciseView} from "./exerciseView";
import {resolveLinkedHorse} from "./linkedHorse";

/** Edita o exercício do treinador autenticado e devolve o exercício já
 * atualizado. Só o autor edita, em qualquer situação profissional menos
 * INATIVO. As cópias do exercício em treinamentos, planos e registros não
 * mudam: a edição só vale para o que for montado depois.
 * @param {string} uid UID do treinador autenticado.
 * @param {ExerciseUpdateInput} input 'id' e alterações validadas.
 * @return {Promise<ExerciseView>} Exercício atualizado, visto pelo autor.
 */
export async function updateExerciseService(
  uid: string,
  input: ExerciseUpdateInput
): Promise<ExerciseView> {
  const [exercise] = await Promise.all([
    findActiveExerciseById(input.id),
    assertActiveAccount(uid, ROLES.trainer),
  ]);
  const notFound = () =>
    new AppError("not-found", "Exercício não encontrado.");
  if (!exercise || !hasAuthor(exercise)) throw notFound();

  if (exercise.treinador._id !== uid) {
    // Só revela que o exercício existe a quem já pode vê-lo; para os
    // demais, ele não existe.
    if (!(await resolveExerciseAccess(exercise, uid))) throw notFound();
    throw new AppError(
      "permission-denied",
      "Apenas o treinador que cadastrou o exercício pode editá-lo."
    );
  }

  const change = planHorseChange(exercise, input.changes);
  let horse: HorseChange<ExerciseHorseRef>;
  if (change === "remove") {
    horse = "remove";
  } else if (change === "keep") {
    // Mantendo o específico, grava de novo o cavalo lido: se outra edição o
    // tirou no meio do caminho, o exercício não fica específico sem cavalo.
    horse = input.changes.privacidade === "ESPECIFICO" && exercise.cavalo ?
      exercise.cavalo :
      "keep";
  } else {
    horse = await resolveLinkedHorse(uid, change);
  }
  const updated = await updateAuthorExercise(
    exercise._id,
    uid,
    buildExerciseUpdate(input.changes, horse, new Date())
  );
  // Excluído entre a leitura e a gravação.
  if (!updated || !hasAuthor(updated)) throw notFound();
  return buildExerciseView(updated, {isAuthor: true, showHorse: true});
}
