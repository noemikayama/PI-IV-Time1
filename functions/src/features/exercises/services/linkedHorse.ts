// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conferência do vínculo do cavalo com o treinador, movida do
// cadastro de exercícios para ser usada também pela galeria.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {findActiveHorseById} from "../../horses";
import type {ExerciseHorseRef} from "../types";

/** Confere se o cavalo está ativo e vinculado ao treinador e monta a
 * referência resumida gravada no exercício.
 * @param {string} uid UID do treinador.
 * @param {ObjectId} id _id do cavalo.
 * @return {Promise<ExerciseHorseRef>} Referência resumida do cavalo.
 */
export async function resolveLinkedHorse(
  uid: string,
  id: ObjectId
): Promise<ExerciseHorseRef> {
  const horse = await findActiveHorseById(id);
  if (!horse) throw new AppError("not-found", "Cavalo não encontrado.");
  if (!horse.treinadores.some((trainer) => trainer._id === uid)) {
    throw new AppError(
      "permission-denied",
      "Você não tem vínculo com este cavalo."
    );
  }
  return {_id: horse._id, codigo: horse.codigo, nome: horse.nome};
}
