// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 04/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Desvínculo do atleta ou do treinador pelo proprietário.
// -----------------------------------------------------------------------------

import type {ClientSession, UpdateFilter} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {
  removeGuardianResponsibility,
  removeHorseFromTrainer,
} from "../repositories/horseSummaryRepository";
import {
  ensureHorseIndexes,
  updateHorseDocument,
} from "../repositories/horseRepository";
import type {HorseDocument, HorseProfile, HorseUnlinkInput} from "../types";
import {assertTrainersCanLeave} from "./assertTrainersCanLeave";
import {
  assertActiveAccount,
  HORSE_RULES,
  loadHorseAccess,
} from "./horseAccess";
import {buildHorseProfile} from "./horseProfile";
import {syncTrainerClients} from "./trainerClients";

// Alteração do cavalo e treinadores cujos clientes precisam ser
// recalculados depois de gravá-la.
type Unlink = {
  update: UpdateFilter<HorseDocument>;
  affectedTrainers: string[];
};

/** Desfaz o vínculo do atleta: retira ATLETA de responsaveis.cavalos (o
 * item só some se não sobrar responsabilidade, como no proprietário que
 * também era atleta).
 * @param {HorseDocument} horse Cavalo lido na transação.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<Unlink>} Alteração do cavalo e treinadores afetados.
 */
async function unlinkAthlete(
  horse: HorseDocument,
  session: ClientSession
): Promise<Unlink> {
  if (!horse.atleta) {
    throw new AppError("not-found", "O cavalo não tem atleta vinculado.");
  }
  await removeGuardianResponsibility(
    horse.atleta._id,
    horse._id,
    "ATLETA",
    session
  );
  return {
    update: {$unset: {atleta: ""}},
    // O atleta pode deixar de ser cliente do treinador do cavalo.
    affectedTrainers: horse.treinadores.map((trainer) => trainer._id),
  };
}

/** Desfaz o vínculo do treinador, recusado se ele for autor do plano ATIVO
 * do cavalo (RF05003).
 * @param {HorseDocument} horse Cavalo lido na transação.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<Unlink>} Alteração do cavalo e treinadores afetados.
 */
async function unlinkTrainer(
  horse: HorseDocument,
  session: ClientSession
): Promise<Unlink> {
  const leaving = horse.treinadores;
  if (leaving.length === 0) {
    throw new AppError("not-found", "O cavalo não tem treinador vinculado.");
  }
  await assertTrainersCanLeave(horse._id, leaving, session);
  for (const trainer of leaving) {
    await removeHorseFromTrainer(trainer._id, horse._id, session);
  }
  return {
    update: {$set: {treinadores: []}},
    affectedTrainers: leaving.map((trainer) => trainer._id),
  };
}

/** Desvincula o atleta ou o treinador do cavalo. Cavalo, listas resumidas
 * e clientes dos treinadores mudam na mesma transação.
 * @param {string} uid UID do proprietário autenticado.
 * @param {HorseUnlinkInput} input Dados validados.
 * @return {Promise<HorseProfile>} Perfil atualizado.
 */
export async function removeHorseLinkService(
  uid: string,
  input: HorseUnlinkInput
): Promise<HorseProfile> {
  await Promise.all([
    assertActiveAccount(uid, ROLES.guardian),
    // idx_cavalos_treinadores sustenta o recálculo dos clientes.
    ensureHorseIndexes(),
  ]);

  const updated = await runInTransaction(async (session) => {
    const {horse} = await loadHorseAccess(
      input.id,
      uid,
      HORSE_RULES.gerenciarVinculos,
      session
    );

    const {update, affectedTrainers} = input.vinculo === "ATLETA" ?
      await unlinkAthlete(horse, session) :
      await unlinkTrainer(horse, session);

    const result = await updateHorseDocument(
      horse._id,
      {...update, $set: {...update.$set, atualizadoEm: new Date()}},
      session
    );
    // Depois de gravar o cavalo: os clientes são derivados de 'cavalos'.
    for (const trainerId of affectedTrainers) {
      await syncTrainerClients(trainerId, session);
    }
    return result;
  });

  if (!updated) {
    throw new AppError("not-found", "Cavalo não encontrado.");
  }
  return buildHorseProfile(updated, uid);
}
