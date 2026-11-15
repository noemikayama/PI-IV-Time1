// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: getHorse vira getHorseProfile e substitui também
// getHorseCurrentPlan e listHorseEvaluations.
// Alteração: Papel do token repassado para conferir a conta ativa.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para consultar um cavalo.
// -----------------------------------------------------------------------------

import {onCall} from "firebase-functions/v2/https";
import {
  defaultFunctionOptions,
} from "../../../shared/config/functionOptions";
import {
  mapErrorToHttpsError,
} from "../../../shared/errors/mapErrorToHttpsErrors";
import {
  requireAuthentication,
} from "../../../shared/middleware/requireAuthentication";
import {getHorseProfileService} from "../services/getHorseProfileService";
import {validateHorseId} from "../validations/validateHorse";

// Perfil do cavalo; proprietário, atleta e treinador do cavalo consultam.
export const getHorseProfile = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireAuthentication(request);
      const id = validateHorseId(request.data);
      return await getHorseProfileService(user, id);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
