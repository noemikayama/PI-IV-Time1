// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Avaliações do cavalo para a etapa "avaliação base" do plano.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {getHorseForUser} from "../../horses";
import type {HorseEvaluationsResult} from "../types";

/** Lista as avaliações do cavalo vinculado ao treinador, da mais recente
 * para a mais antiga. Lê só o resumo em cavalos.avaliacoes (já ordenado),
 * sem consultar a coleção de avaliações.
 * @param {string} uid UID do treinador autenticado.
 * @param {ObjectId} horseId _id do cavalo.
 * @return {Promise<HorseEvaluationsResult>} Avaliações (lista vazia se não
 * houver).
 */
export async function listHorseEvaluationsService(
  uid: string,
  horseId: ObjectId
): Promise<HorseEvaluationsResult> {
  const {horse} = await getHorseForUser({uid, role: ROLES.trainer}, horseId);
  return {
    avaliacoes: horse.avaliacoes.map((evaluation) => ({
      id: evaluation._id.toHexString(),
      codigo: evaluation.codigo,
      data: evaluation.data,
    })),
  };
}
