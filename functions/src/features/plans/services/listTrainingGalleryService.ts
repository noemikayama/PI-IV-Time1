// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Galeria de treinamentos do cadastro de plano e separação dos
// treinamentos que usam exercício específico de outro cavalo.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {normalizeForSearch} from "../../../shared/utils/search";
import {findForeignSpecificExerciseIds} from "../../exercises";
import {getHorseForUser} from "../../horses";
import {findTrainerTrainings} from "../../training";
import type {TrainingDocument} from "../../training";
import type {
  TrainingGalleryInput,
  TrainingGalleryItem,
  TrainingGalleryResult,
} from "../types";

const collator = new Intl.Collator("pt-BR", {
  sensitivity: "base",
  numeric: true,
});

/** Separa os treinamentos que usam exercício específico de outro cavalo,
 * que não podem entrar no plano do cavalo informado. A cópia do exercício
 * no treinamento não guarda a privacidade, então ela é lida em
 * 'exercicios' (uma consulta para todos).
 * @param {TrainingDocument[]} trainings Treinamentos do treinador.
 * @param {ObjectId} horseId _id do cavalo do plano.
 * @return {Promise<Object>} Treinamentos aceitos e recusados.
 */
export async function splitByHorse(
  trainings: TrainingDocument[],
  horseId: ObjectId
): Promise<{usable: TrainingDocument[]; blocked: TrainingDocument[]}> {
  const exerciseIds = new Map(
    trainings.flatMap((training) =>
      training.exercicios.map((exercise) => [
        exercise._id.toHexString(),
        exercise._id,
      ])
    )
  );
  const foreign = new Set(
    (await findForeignSpecificExerciseIds([...exerciseIds.values()], horseId))
      .map((id) => id.toHexString())
  );

  const usable: TrainingDocument[] = [];
  const blocked: TrainingDocument[] = [];
  for (const training of trainings) {
    const isBlocked = training.exercicios.some((exercise) =>
      foreign.has(exercise._id.toHexString())
    );
    (isBlocked ? blocked : usable).push(training);
  }
  return {usable, blocked};
}

/** Converte o treinamento no card da galeria.
 * @param {TrainingDocument} training Treinamento lido do banco.
 * @return {TrainingGalleryItem} Card da galeria.
 */
const toGalleryItem = (training: TrainingDocument): TrainingGalleryItem => ({
  id: training._id.toHexString(),
  codigo: training.codigo,
  titulo: training.titulo,
  duracaoEstimadaMinutos: training.duracaoEstimadaMinutos,
  exercicios: training.exercicios.map((exercise) => exercise.nome),
});

/** Lista os treinamentos do treinador que podem entrar no plano do cavalo
 * (vinculado a ele), em ordem alfabética. A busca filtra por parte do
 * título, sem diferenciar maiúsculas nem acentos.
 * @param {string} uid UID do treinador autenticado.
 * @param {TrainingGalleryInput} input Filtros validados.
 * @return {Promise<TrainingGalleryResult>} Treinamentos encontrados.
 */
export async function listTrainingGalleryService(
  uid: string,
  input: TrainingGalleryInput
): Promise<TrainingGalleryResult> {
  const [trainings] = await Promise.all([
    findTrainerTrainings(uid),
    getHorseForUser({uid, role: ROLES.trainer}, input.cavaloId),
  ]);

  const term = input.busca && normalizeForSearch(input.busca);
  const found = term ?
    trainings.filter((training) =>
      normalizeForSearch(training.titulo).includes(term)
    ) :
    trainings;

  const {usable} = await splitByHorse(found, input.cavaloId);
  return {
    treinamentos: usable
      .sort((a, b) => collator.compare(a.titulo, b.titulo))
      .map(toGalleryItem),
  };
}
