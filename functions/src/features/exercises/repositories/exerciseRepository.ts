// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Período opcional de cadastro, usado pelo dashboard.
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
import {inPeriod} from "../../../shared/utils/dates";
import type {DatePeriod} from "../../../shared/utils/dates";

// Usa idx_exercicios_treinador. Exercícios removidos (ativo = false) não
// contam, nem os da plataforma, que não têm treinador.
/** Conta os exercícios ativos cadastrados pelo treinador.
 * @param {string} trainerId UID do treinador.
 * @param {DatePeriod} createdIn Período de 'criadoEm' ou null (todos).
 */
export async function countActiveExercisesByTrainer(
  trainerId: string,
  createdIn: DatePeriod | null = null
): Promise<number> {
  const db = await getDatabase();
  return db
    .collection(COLLECTIONS.Exercicios)
    .countDocuments({
      "treinador._id": trainerId,
      "ativo": true,
      ...(createdIn ? inPeriod("criadoEm", createdIn) : {}),
    });
}
