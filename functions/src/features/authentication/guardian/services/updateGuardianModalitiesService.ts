// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Edição das modalidades vinculadas ao responsável.
// -----------------------------------------------------------------------------

import {AppError} from "../../../../shared/errors/AppError";
import {findModalitiesByIds} from "../../../modalities";
import {
  findGuardianById,
  updateGuardianModalities,
} from "../repositories/guardianRepository";
import type {
  GuardianModality,
  UpdateGuardianModalitiesInput,
  UpdateGuardianModalitiesResult,
} from "../types";

/** Substitui as modalidades vinculadas ao responsável.
 * Só cria vínculos com modalidades já cadastradas; o catálogo não é alterado.
 * @param {string} uid UID do usuário autenticado.
 * @param {UpdateGuardianModalitiesInput} input IDs validados.
 * @return {Promise<UpdateGuardianModalitiesResult>} Modalidades vinculadas.
 */
export async function updateGuardianModalitiesService(
  uid: string,
  input: UpdateGuardianModalitiesInput
): Promise<UpdateGuardianModalitiesResult> {
  const guardian = await findGuardianById(uid);

  if (!guardian) {
    throw new AppError("not-found", "Perfil não encontrado.");
  }
  if (guardian.situacaoCadastral === "INATIVO") {
    throw new AppError("permission-denied", "Cadastro inativo.");
  }

  const found = await findModalitiesByIds(input.modalidadeIds);
  const catalog = new Map(found.map((item) => [item._id.toHexString(), item]));

  // Mantém a ordem informada e copia codigo/nome do catálogo atual.
  const modalidades: GuardianModality[] = input.modalidadeIds.map((id) => {
    const modality = catalog.get(id.toHexString());
    if (!modality) {
      throw new AppError("not-found", "Modalidade não encontrada.");
    }
    return {_id: modality._id, codigo: modality.codigo, nome: modality.nome};
  });

  const updated = await updateGuardianModalities(uid, modalidades, new Date());
  if (!updated) {
    throw new AppError("not-found", "Perfil não encontrado.");
  }

  return {
    modalidades: modalidades.map((item) => ({
      id: item._id.toHexString(),
      codigo: item.codigo,
      nome: item.nome,
    })),
  };
}
