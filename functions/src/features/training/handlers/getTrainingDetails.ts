// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable dos detalhes do treinamento.
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
import {getTrainingDetailsService} from "../services/getTrainingDetailsService";
import {
  validateTrainingDetailsInput,
} from "../validations/validateTrainingDetails";

// Exige só o login: o service lê o cargo (treinador ou responsável) da conta
// no MongoDB e confere o acesso ao treinamento.
export const getTrainingDetails = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireAuthentication(request);
      const input = validateTrainingDetailsInput(request.data);
      return await getTrainingDetailsService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
