// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cancelamento do plano de treinamento.
// -----------------------------------------------------------------------------

import {onCall} from "firebase-functions/v2/https";
import {
  defaultFunctionOptions,
} from "../../../shared/config/functionOptions";
import {ROLES} from "../../../shared/constants/roles";
import {
  mapErrorToHttpsError,
} from "../../../shared/errors/mapErrorToHttpsErrors";
import {requireRole} from "../../../shared/middleware/requireRole";
import {
  cancelTrainingPlanService,
} from "../services/cancelTrainingPlanService";
import {validatePlanId} from "../validations/validateTrainingPlan";

// Exige login de treinador; o responsável recebe 'permission-denied'.
export const cancelTrainingPlan = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireRole(request, ROLES.trainer);
      const input = validatePlanId(request.data);
      return await cancelTrainingPlanService(user, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
