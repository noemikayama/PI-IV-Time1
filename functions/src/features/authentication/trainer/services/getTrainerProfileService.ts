// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: _id dos cavalos convertido para string hexadecimal.
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
    // O callable não converte ObjectId: sem isto, _id chega ao app como
    // objeto. Lista usada também na seleção de cavalo do exercício.
    cavalos: trainer.cavalos.map((cavalo) => ({
      ...cavalo,
      _id: cavalo._id.toHexString(),
    })),
    criadoEm: trainer.criadoEm.toISOString(),
    atualizadoEm: trainer.atualizadoEm.toISOString(),
  };
}
