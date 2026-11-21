// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para listar os cavalos do usuário.
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
import {listHorsesService} from "../services/listHorsesService";
import {validateHorseList} from "../validations/validateHorseList";

// Responsáveis e treinadores; o service confere o papel e a conta ativa.
export const listHorses = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireAuthentication(request);
      const input = validateHorseList(request.data);
      return await listHorsesService(user, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
