// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do endpoint callable para cadastrar treinadores.
// ----------------------------------------------------------------------------- 

import {onCall} from "firebase-functions/v2/https";
import {defaultFunctionOptions} from "../../../../shared/config/functionOptions";
import {mapErrorToHttpsError} from "../../../../shared/errors/mapErrorToHttpsErrors";
import {registerProfessionalService} from "../services/registerProfessionalService";
import {validateProfessionalRegistration} from "../validations/validateProfessionalRegistration";

// Cadastro público, não exige autenticação.
export const registerProfessional = onCall(defaultFunctionOptions, async (request) => {
    try {
        const input = validateProfessionalRegistration(request.data);
        return await registerProfessionalService(input);
    } catch (error) {
        throw mapErrorToHttpsError(error);
    }
});
