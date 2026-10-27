// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta do cavalo com a idade calculada.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {findActiveHorseById} from "../repositories/horseRepository";
import type {HorseView} from "../types";
import {responsibilitiesOf, toHorseView} from "./horseMappers";

/** Retorna o cavalo para o proprietário, o atleta ou um de seus
 * treinadores. Para os demais, o cavalo é tratado como inexistente.
 * @param {string} uid UID do usuário autenticado.
 * @param {ObjectId} id _id do cavalo.
 */
export async function getHorseService(
  uid: string,
  id: ObjectId
): Promise<HorseView> {
  const horse = await findActiveHorseById(id);
  const allowed = horse && (
    responsibilitiesOf(horse, uid).length > 0 ||
    horse.treinadores.some((trainer) => trainer._id === uid)
  );
  if (!horse || !allowed) {
    throw new AppError("not-found", "Cavalo não encontrado.");
  }
  return toHorseView(horse, uid);
}
