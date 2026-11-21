// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Listagem das modalidades disponíveis.
// -----------------------------------------------------------------------------

import {findAllModalities} from "../repositories/modalityRepository";
import type {Modality, ModalityDocument} from "../types";

/** Converte o documento do banco para o formato enviado ao app.
 * @param {ModalityDocument} modality Documento da modalidade.
 * @return {Modality} Modalidade com o id em string.
 */
function toModality(modality: ModalityDocument): Modality {
  return {
    id: modality._id.toHexString(),
    codigo: modality.codigo,
    nome: modality.nome,
    descricao: modality.descricao,
  };
}

/** Retorna as modalidades disponíveis para o cadastro do treinador.
 * @return {Promise<Modality[]>} Modalidades em ordem alfabética.
 */
export async function getModalitiesService(): Promise<Modality[]> {
  const modalities = await findAllModalities();
  return modalities.map(toModality);
}
