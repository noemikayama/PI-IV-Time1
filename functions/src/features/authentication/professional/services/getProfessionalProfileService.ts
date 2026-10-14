// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta do perfil do treinador autenticado.
// -----------------------------------------------------------------------------

import {AppError} from "../../../../shared/errors/AppError";
import {findProfessionalById} from "../repositories/professionalRepository";
import type {ProfessionalProfile} from "../types";

export async function getProfessionalProfileService(
    uid: string
): Promise<ProfessionalProfile> {
    const professional = await findProfessionalById(uid);

    if (!professional) {
        throw new AppError("not-found", "Perfil não encontrado.");
    }
    if (professional.situacaoProfissional === "INATIVO") {
        throw new AppError("permission-denied", "Cadastro inativo.");
    }
    
    return {
        ...professional,
        criadoEm: professional.criadoEm.toISOString(),
        atualizadoEm: professional.atualizadoEm.toISOString(),
    };
}
