// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Edição do nome do responsável autenticado.
// -----------------------------------------------------------------------------

import {runInTransaction} from "../../../../shared/config/mongodb";
import {AppError} from "../../../../shared/errors/AppError";
import {updateAuthDisplayName} from "../../shared";
import {
  findGuardianById,
  renameGuardianRefs,
  updateGuardianName,
} from "../repositories/guardianRepository";
import type {
  UpdateGuardianProfileInput,
  UpdateGuardianProfileResult,
} from "../types";

/** Altera o nome do responsável. A senha tem fluxo próprio
 * (requestPasswordReset) e não é tratada aqui.
 * @param {string} uid UID do usuário autenticado.
 * @param {UpdateGuardianProfileInput} input Nome completo validado.
 * @return {Promise<UpdateGuardianProfileResult>} Nome e data da alteração.
 */
export async function updateGuardianProfileService(
  uid: string,
  input: UpdateGuardianProfileInput
): Promise<UpdateGuardianProfileResult> {
  const guardian = await findGuardianById(uid);

  if (!guardian) {
    throw new AppError("not-found", "Perfil não encontrado.");
  }
  if (guardian.situacaoCadastral === "INATIVO") {
    throw new AppError("permission-denied", "Cadastro inativo.");
  }

  // Nome igual ao atual não é alteração: nada é gravado e 'atualizadoEm'
  // é mantido.
  if (input.nome === guardian.nome) {
    return {
      nome: guardian.nome,
      atualizadoEm: guardian.atualizadoEm.toISOString(),
    };
  }

  const updated = await runInTransaction(async (session) => {
    const doc = await updateGuardianName(uid, input.nome, new Date(), session);
    // O nome é copiado em cavalos (proprietario/atleta) e
    // treinadores.clientes.
    if (doc) await renameGuardianRefs(uid, doc.nome, session);
    return doc;
  });

  // O filtro exige cadastro ativo; pode ter sido inativado nesse intervalo.
  if (!updated) {
    throw new AppError("permission-denied", "Conta inativa ou inexistente.");
  }
  await updateAuthDisplayName(uid, updated.nome);

  return {
    nome: updated.nome,
    atualizadoEm: updated.atualizadoEm.toISOString(),
  };
}
