// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Microchip editável, modalidade obrigatória, conferência da
// conta ativa e cópias do nome e do microchip em todas as coleções.
// Alteração: Listas de saúde e de lesões editadas por inclusão e remoção,
// aplicadas sobre o documento lido na transação.
// Alteração: Verificação de acesso pelo helper central (horseAccess).
// Alteração: Regras de saúde e de lesões vindas de horseHealth.ts.
// Alteração: syncHorseRefs vindo de horseSummaryRepository.ts.
// Alteração: Devolve o perfil atualizado (HorseProfile).
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Edição dos dados, da saúde e das lesões do cavalo.
// -----------------------------------------------------------------------------

import {runInTransaction} from "../../../shared/config/mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {
  ensureHorseIndexes,
  updateHorseDocument,
} from "../repositories/horseRepository";
import {syncHorseRefs} from "../repositories/horseSummaryRepository";
import type {HorseProfile, HorseUpdateInput} from "../types";
import {applyHealthChanges, assertInjuriesAfterBirth} from "./horseHealth";
import {
  assertActiveAccount,
  HORSE_RULES,
  loadHorseAccess,
} from "./horseAccess";
import {buildHorseProfile} from "./horseProfile";
import {resolveModality} from "./resolveModality";

/** Altera os campos enviados e devolve o perfil atualizado.
 * @param {string} uid UID do responsável autenticado.
 * @param {HorseUpdateInput} input Alterações validadas.
 * @return {Promise<HorseProfile>} Perfil atualizado.
 */
export async function updateHorseService(
  uid: string,
  input: HorseUpdateInput
): Promise<HorseProfile> {
  const {
    modalidadeId,
    limitacoesFisicas,
    observacoesSaude,
    historicoLesoes,
    ...fields
  } = input.changes;

  // Leituras e preparos que não dependem do cavalo ficam fora da transação.
  const [modalidade] = await Promise.all([
    modalidadeId ? resolveModality(modalidadeId) : undefined,
    assertActiveAccount(uid, ROLES.guardian),
    // O índice único do microchip deve existir antes da transação.
    fields.codigo !== undefined ? ensureHorseIndexes() : undefined,
  ]);

  // O cavalo é lido dentro da transação: se outra edição o gravar antes do
  // commit, a transação é repetida sobre o documento novo, então as
  // inclusões e remoções nunca descartam o que outra pessoa gravou.
  const updated = await runInTransaction(async (session) => {
    const {horse: current} = await loadHorseAccess(
      input.id,
      uid,
      HORSE_RULES.editar,
      session
    );

    const lists = applyHealthChanges(current, {
      limitacoesFisicas,
      observacoesSaude,
      historicoLesoes,
    });
    assertInjuriesAfterBirth(
      fields.dataNascimento ?? current.dataNascimento,
      lists.historicoLesoes ?? current.historicoLesoes
    );

    const horse = await updateHorseDocument(
      input.id,
      {
        $set: {
          ...fields,
          ...lists,
          ...(modalidade && {modalidade}),
          atualizadoEm: new Date(),
        },
      },
      session
    );
    // Microchip e nome são copiados em responsaveis, treinadores,
    // avaliacoes, planos, registros_treino e exercicios.
    if (horse && (fields.nome !== undefined || fields.codigo !== undefined)) {
      await syncHorseRefs(horse._id, horse, session);
    }
    return horse;
  });

  if (!updated) {
    throw new AppError("not-found", "Cavalo não encontrado.");
  }
  return buildHorseProfile(updated, uid);
}
