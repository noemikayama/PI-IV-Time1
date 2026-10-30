// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 29/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Carga do treinador ativo e conversão dos anexos compartilhadas
// com a edição do perfil.
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

import {
  loadActiveTrainer,
  toAttachmentViews,
} from "./trainerAttachmentService";
import type {TrainerProfile} from "../types";

/** Retorna os dados públicos do perfil do treinador.
 * @param {string} uid UID do usuário.
 */
export async function getTrainerProfileService(
  uid: string
): Promise<TrainerProfile> {
  const trainer = await loadActiveTrainer(uid);

  return {
    ...trainer,
    ...(await toAttachmentViews(trainer)),
    criadoEm: trainer.criadoEm.toISOString(),
    atualizadoEm: trainer.atualizadoEm.toISOString(),
  };
}
