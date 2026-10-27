// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Edição dos dados, da saúde e das lesões do cavalo.
// -----------------------------------------------------------------------------

import type {UpdateFilter} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {
  findActiveHorseById,
  renameHorseRefs,
  updateHorseDocument,
} from "../repositories/horseRepository";
import type {HorseDocument, HorseUpdateInput, HorseView} from "../types";
import {assertInjuriesAfterBirth} from "../validations/validateHorse";
import {toHorseView} from "./horseMappers";
import {resolveModality} from "./resolveModality";

/** Altera os campos enviados e devolve o cavalo atualizado.
 * @param {string} uid UID do responsável autenticado.
 * @param {HorseUpdateInput} input Alterações validadas.
 */
export async function updateHorseService(
  uid: string,
  input: HorseUpdateInput
): Promise<HorseView> {
  const current = await findActiveHorseById(input.id);
  if (!current) {
    throw new AppError("not-found", "Cavalo não encontrado.");
  }
  if (current.proprietario._id !== uid) {
    throw new AppError(
      "permission-denied",
      "Apenas o proprietário pode editar o cavalo."
    );
  }

  const {modalidadeId, ...fields} = input.changes;
  assertInjuriesAfterBirth(
    fields.dataNascimento ?? current.dataNascimento,
    fields.historicoLesoes ?? current.historicoLesoes
  );

  const update: UpdateFilter<HorseDocument> = {
    $set: {...fields, atualizadoEm: new Date()},
  };
  if (modalidadeId === null) {
    update.$unset = {modalidade: ""};
  } else if (modalidadeId) {
    const modalidade = await resolveModality(modalidadeId);
    update.$set = {...update.$set, modalidade};
  }

  const updated = await runInTransaction(async (session) => {
    const horse = await updateHorseDocument(input.id, update, session);
    // O nome é copiado em responsaveis.cavalos e treinadores.cavalos.
    // Decidido na transação: uma leitura anterior pode estar desatualizada.
    if (horse && fields.nome !== undefined) {
      await renameHorseRefs(horse._id, horse.nome, session);
    }
    return horse;
  });

  if (!updated) {
    throw new AppError("not-found", "Cavalo não encontrado.");
  }
  return toHorseView(updated, uid);
}
