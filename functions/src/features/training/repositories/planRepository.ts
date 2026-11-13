// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta do autor do plano ativo do cavalo, movida da feature
// de cavalos.
// -----------------------------------------------------------------------------

// Coleção 'planos'. Consultas usadas por outras features enquanto a feature
// de planos não existe; o índice idx_planos_cavalo_ativo (DD 5.1) será
// criado por ela.
import type {ClientSession, ObjectId} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";

/** Indica se o treinador é autor do plano ATIVO do cavalo (RF05003).
 * @param {ObjectId} horseId _id do cavalo.
 * @param {string} trainerId UID do treinador.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<boolean>} Se existe plano ATIVO dele no cavalo.
 */
export async function isActivePlanAuthor(
  horseId: ObjectId,
  trainerId: string,
  session: ClientSession
): Promise<boolean> {
  const db = await getDatabase();
  const plan = await db.collection(COLLECTIONS.Planos).findOne(
    {
      "cavalo._id": horseId,
      "status": "ATIVO",
      "treinador._id": trainerId,
    },
    {projection: {_id: 1}, session}
  );
  return plan !== null;
}
