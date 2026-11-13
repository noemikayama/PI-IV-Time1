// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Inclusão de limitação, observação de saúde ou lesão por
// proprietário, atleta ou treinador.
// Alteração: Verificação de acesso pelo helper central (horseAccess).
// Alteração: Regras de saúde e de lesões vindas de horseHealth.ts.
// Alteração: Inclusão exclusiva do proprietário (matriz de permissões);
// devolve o perfil atualizado.
// -----------------------------------------------------------------------------

import {runInTransaction} from "../../../shared/config/mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {pushHealthEntry} from "../repositories/horseRepository";
import type {HorseHealthEntryInput, HorseProfile} from "../types";
import {applyHealthChanges, assertInjuriesAfterBirth} from "./horseHealth";
import {
  assertActiveAccount,
  HORSE_RULES,
  loadHorseAccess,
} from "./horseAccess";
import {buildHorseProfile} from "./horseProfile";

/** Inclui um item em uma lista de saúde. Só o proprietário inclui, como
 * edita e remove (updateHorse). O item entra com $push, então nada do que
 * já está gravado é regravado.
 * @param {string} uid UID do responsável autenticado.
 * @param {HorseHealthEntryInput} input Dados validados.
 * @return {Promise<HorseProfile>} Perfil atualizado.
 */
export async function addHorseHealthEntryService(
  uid: string,
  input: HorseHealthEntryInput
): Promise<HorseProfile> {
  await assertActiveAccount(uid, ROLES.guardian);

  const updated = await runInTransaction(async (session) => {
    const {horse} = await loadHorseAccess(
      input.id,
      uid,
      HORSE_RULES.adicionarSaude,
      session
    );

    // Repetição e limite são conferidos sobre a lista lida na transação;
    // uma inclusão simultânea faz a transação ser repetida.
    applyHealthChanges(horse, {
      [input.lista]: {adicionar: [input.item], remover: []},
    });
    if (input.lista === "historicoLesoes") {
      assertInjuriesAfterBirth(horse.dataNascimento, [input.item]);
    }
    return pushHealthEntry(horse._id, input, session);
  });

  if (!updated) {
    throw new AppError("not-found", "Cavalo não encontrado.");
  }
  return buildHorseProfile(updated, uid);
}
