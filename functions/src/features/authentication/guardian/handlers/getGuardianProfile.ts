// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do endpoint callable para obter o perfil de um responsável.
// ----------------------------------------------------------------------------- 

import {onCall} from "firebase-functions/v2/https";
import {defaultFunctionOptions} from "../../../../shared/config/functionOptions";
import {ROLES} from "../../../../shared/constants/roles";
import {mapErrorToHttpsError} from "../../../../shared/errors/mapErrorToHttpsErrors";
import {requireRole} from "../../../../shared/middleware/requireRole";
import {getGuardianProfileService} from "../services/getGuardianProfileService";

export const getGuardianProfile = onCall(defaultFunctionOptions, async (request) => {
    try {
        const user = requireRole(request, ROLES.guardian); // exige login e role guardian
        return await getGuardianProfileService(user.uid);
    } catch (error) {
        throw mapErrorToHttpsError(error);
    }
});
