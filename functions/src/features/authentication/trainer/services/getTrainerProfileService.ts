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
// Alteração: Perfil devolve os anexos com URL assinada de leitura.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta do perfil do treinador autenticado.
// -----------------------------------------------------------------------------

import {AppError} from "../../../../shared/errors/AppError";
import {findTrainerById} from "../repositories/trainerRepository";
import {toAttachmentView} from "./trainerAttachmentService";
import type {TrainerProfile} from "../types";

/** Retorna os dados públicos do perfil do treinador.
 * @param {string} uid UID do usuário.
 */
export async function getTrainerProfileService(
  uid: string
): Promise<TrainerProfile> {
  const trainer = await findTrainerById(uid);

  if (!trainer) {
    throw new AppError("not-found", "Perfil não encontrado.");
  }
  if (trainer.situacaoProfissional === "INATIVO") {
    throw new AppError("permission-denied", "Cadastro inativo.");
  }

  const [experiencias, certificacoes] = await Promise.all([
    typeof trainer.experiencias === "string" ?
      toAttachmentView(trainer.experiencias) :
      null,
    Promise.all(trainer.certificacoes.map(toAttachmentView)),
  ]);

  return {
    ...trainer,
    experiencias,
    certificacoes,
    criadoEm: trainer.criadoEm.toISOString(),
    atualizadoEm: trainer.atualizadoEm.toISOString(),
  };
}
