// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
import {getHorseService} from "../services/getHorseService";
import {validateHorseId} from "../validations/validateHorse";

// Responsáveis e treinadores do cavalo podem consultá-lo.
export const getHorse = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireAuthentication(request);
      const input = validateHorseId(request.data);
      return await getHorseService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
