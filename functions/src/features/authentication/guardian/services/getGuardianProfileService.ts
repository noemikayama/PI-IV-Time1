// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta do perfil do responsável autenticado.
// -----------------------------------------------------------------------------

import {AppError} from "../../../../shared/errors/AppError";
import {findGuardianById} from "../repositories/guardianRepository";
import type {GuardianProfile} from "../types";

/** Retorna os dados públicos do perfil do responsável.
 * @param {string} uid UID do usuário.
 */
export async function getGuardianProfileService(
  uid: string
): Promise<GuardianProfile> {
  const guardian = await findGuardianById(uid);

  if (!guardian) {
    throw new AppError("not-found", "Perfil não encontrado.");
  }
  if (guardian.situacaoCadastral === "INATIVO") {
    throw new AppError("permission-denied", "Cadastro inativo.");
  }
  return {
    ...guardian,
    criadoEm: guardian.criadoEm.toISOString(),
    atualizadoEm: guardian.atualizadoEm.toISOString(),
  };
}
