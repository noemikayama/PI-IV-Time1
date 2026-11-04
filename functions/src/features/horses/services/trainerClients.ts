// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Recálculo dos clientes do treinador, usado pelos vínculos e
// pela exclusão do cavalo.
// Alteração: Clientes derivados lidos de horseRepository.ts (coleção
// 'cavalos').
// -----------------------------------------------------------------------------

import type {ClientSession} from "mongodb";
import {findClientsFromHorses} from "../repositories/horseRepository";
import {
  findTrainerClients,
  setTrainerClients,
} from "../repositories/horseSummaryRepository";
import type {AccountRef} from "../types";

/** Recalcula treinadores.clientes a partir dos cavalos do treinador
 * (DD 5.2): quem continua cliente mantém a posição e quem passou a ser
 * entra no fim.
 * @param {string} trainerId UID do treinador.
 * @param {ClientSession} session Sessão da transação.
 */
export async function syncTrainerClients(
  trainerId: string,
  session: ClientSession
): Promise<void> {
  const derived = await findClientsFromHorses(trainerId, session);
  const current = await findTrainerClients(trainerId, session);
  if (current === null) return;

  const byId = new Map(derived.map((client) => [client._id, client]));
  const kept = current
    .filter((client) => byId.has(client._id))
    .map((client) => byId.get(client._id) as AccountRef);
  const keptIds = new Set(kept.map((client) => client._id));
  const next = [
    ...kept,
    ...derived.filter((client) => !keptIds.has(client._id)),
  ];

  if (JSON.stringify(next) !== JSON.stringify(current)) {
    await setTrainerClients(trainerId, next, session);
  }
}
