// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Contagem de exercícios ativos do treinador para a home.
// -----------------------------------------------------------------------------

import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";

/** Conta os exercícios ativos cadastrados pelo treinador.
 * @param {string} trainerId UID do treinador.
 */
export async function countActiveExercisesByTrainer(
  trainerId: string
): Promise<number> {
  const db = await getDatabase();
  return db
    .collection(COLLECTIONS.Exercicios)
    .countDocuments({"treinador._id": trainerId, "ativo": true});
}
