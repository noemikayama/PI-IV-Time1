// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Visualização do plano de treinamento.
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
import {
  getTrainingPlanDetailsService,
} from "../services/getTrainingPlanDetailsService";
import {validatePlanId} from "../validations/validateTrainingPlan";

// Treinador ou responsável; o perfil é conferido na conta do MongoDB.
export const getTrainingPlanDetails = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireAuthentication(request);
      const input = validatePlanId(request.data);
      return await getTrainingPlanDetailsService(user, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
