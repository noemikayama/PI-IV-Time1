// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exclusão lógica do cavalo pelo proprietário.
// Alteração: Verificação de acesso pelo helper central (horseAccess).
// Alteração: Listas resumidas via horseSummaryRepository.ts.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {
  removeHorseFromGuardian,
  removeHorseFromTrainer,
} from "../repositories/horseSummaryRepository";
import {
  deactivateHorse,
  ensureHorseIndexes,
} from "../repositories/horseRepository";
import {
  assertActiveAccount,
  HORSE_RULES,
  loadHorseAccess,
} from "./horseAccess";
import {syncTrainerClients} from "./trainerClients";

/** Exclui o cavalo de forma lógica (DD 5.2, "Desativar um cavalo"): ele
 * passa a INATIVO, sai de responsaveis.cavalos e de treinadores.cavalos, e
 * os clientes dos treinadores são recalculados. O documento, as imagens,
 * as avaliações, os planos e os registros são preservados, e o microchip
 * continua reservado.
 * @param {string} uid UID do proprietário autenticado.
 * @param {ObjectId} id _id do cavalo.
 * @return {Promise<{excluido: true}>} Confirmação da exclusão.
 */
export async function deleteHorseService(
  uid: string,
  id: ObjectId
): Promise<{excluido: true}> {
  await Promise.all([
    assertActiveAccount(uid, ROLES.guardian),
    // idx_cavalos_treinadores sustenta o recálculo dos clientes.
    ensureHorseIndexes(),
  ]);

  await runInTransaction(async (session) => {
    const {horse} = await loadHorseAccess(
      id,
      uid,
      HORSE_RULES.excluir,
      session
    );

    if (!(await deactivateHorse(horse._id, session))) {
      throw new AppError("not-found", "Cavalo não encontrado.");
    }

    // Proprietário e atleta podem ser a mesma pessoa.
    const guardians = new Set([horse.proprietario._id]);
    if (horse.atleta) guardians.add(horse.atleta._id);
    for (const guardianId of guardians) {
      await removeHorseFromGuardian(guardianId, horse._id, session);
    }

    // Depois de inativar: os clientes são derivados dos cavalos ATIVOS.
    for (const trainer of horse.treinadores) {
      await removeHorseFromTrainer(trainer._id, horse._id, session);
      await syncTrainerClients(trainer._id, session);
    }
  });

  return {excluido: true};
}
