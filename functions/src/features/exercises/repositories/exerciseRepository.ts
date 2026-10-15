// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Contagem de exercícios ativos do treinador para a home.
// -----------------------------------------------------------------------------

import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";

/** Conta os exercícios ativos cadastrados pelo treinador.
 * @param {string} professionalId UID do treinador.
 */
export async function countActiveExercisesByProfessional(
  professionalId: string
): Promise<number> {
  const db = await getDatabase();
  return db
    .collection(COLLECTIONS.exercicios)
    .countDocuments({"treinador._id": professionalId, "ativo": true});
}
