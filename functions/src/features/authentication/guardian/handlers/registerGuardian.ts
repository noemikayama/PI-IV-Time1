// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do endpoint callable para cadastrar responsáveis.
// ----------------------------------------------------------------------------- 

import {onCall} from "firebase-functions/v2/https";
import {defaultFunctionOptions} from "../../../../shared/config/functionOptions";
import {mapErrorToHttpsError} from "../../../../shared/errors/mapErrorToHttpsErrors";
import {registerGuardianService} from "../services/registerGuardianService";
import {validateGuardianRegistration} from "../validations/validateGuardianRegistration";

// Cadastro público, não exige autenticação.
export const registerGuardian = onCall(defaultFunctionOptions, async (request) => {
    try {
        const input = validateGuardianRegistration(request.data);
        return await registerGuardianService(input);
    } catch (error) {
        throw mapErrorToHttpsError(error);
    }
});
