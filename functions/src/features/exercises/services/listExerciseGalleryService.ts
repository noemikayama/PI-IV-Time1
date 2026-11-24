// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Galeria de exercícios do cadastro de treinamentos.
// -----------------------------------------------------------------------------

import {ROLES} from "../../../shared/constants/roles";
import {filterByName} from "../../../shared/utils/search";
import {assertActiveAccount} from "../../horses";
import {findGalleryExercises} from "../repositories/exerciseRepository";
import type {
  ExerciseGalleryInput,
  ExerciseGalleryItem,
  ExerciseGalleryResult,
  ExerciseGallerySource,
} from "../types";
import {resolveLinkedHorse} from "./linkedHorse";

const collator = new Intl.Collator("pt-BR", {
  sensitivity: "base",
  numeric: true,
});

/** Converte o exercício no item da galeria (ObjectId vira string).
 * @param {ExerciseGallerySource} exercise Exercício lido do banco.
 * @return {ExerciseGalleryItem} Item da galeria.
 */
function toGalleryItem(exercise: ExerciseGallerySource): ExerciseGalleryItem {
  const {cavalo} = exercise;
  return {
    id: exercise._id.toHexString(),
    nome: exercise.nome,
    duracaoPadraoMinutos: exercise.duracaoPadraoMinutos,
    privacidade: exercise.privacidade,
    ...(cavalo && {
      cavalo: {
        id: cavalo._id.toHexString(),
        codigo: cavalo.codigo,
        nome: cavalo.nome,
      },
    }),
  };
}

/** Lista a galeria do treinador, em ordem alfabética e sem paginação. Sem
 * cavalo, traz os exercícios genéricos dele; com cavalo (vinculado a ele),
 * os específicos que ele cadastrou para esse cavalo. A busca por nome vale
 * nos dois casos.
 * @param {string} uid UID do treinador autenticado.
 * @param {ExerciseGalleryInput} input Filtros validados.
 * @return {Promise<ExerciseGalleryResult>} Exercícios encontrados.
 */
export async function listExerciseGalleryService(
  uid: string,
  input: ExerciseGalleryInput
): Promise<ExerciseGalleryResult> {
  await assertActiveAccount(uid, ROLES.trainer);
  if (input.cavaloId) await resolveLinkedHorse(uid, input.cavaloId);

  const exercises = await findGalleryExercises(
    uid,
    input.cavaloId ? "ESPECIFICO" : "GENERICO",
    input.cavaloId
  );
  const items = filterByName(exercises, input.busca)
    .map(toGalleryItem)
    .sort((a, b) =>
      collator.compare(a.nome, b.nome) || a.id.localeCompare(b.id)
    );
  return {exercicios: items};
}
