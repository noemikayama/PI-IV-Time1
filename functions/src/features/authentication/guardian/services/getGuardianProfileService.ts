// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: _id dos cavalos e das modalidades convertido para string
// hexadecimal.
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
    // O callable não converte ObjectId: sem isto, _id chega ao app como
    // objeto.
    cavalos: guardian.cavalos.map((cavalo) => ({
      ...cavalo,
      _id: cavalo._id.toHexString(),
    })),
    modalidades: guardian.modalidades.map((modalidade) => ({
      ...modalidade,
      _id: modalidade._id.toHexString(),
    })),
    criadoEm: guardian.criadoEm.toISOString(),
    atualizadoEm: guardian.atualizadoEm.toISOString(),
  };
}
