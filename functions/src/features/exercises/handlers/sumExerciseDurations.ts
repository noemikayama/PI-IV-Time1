// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable do tempo total dos exercícios selecionados.
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
  sumExerciseDurationsService,
} from "../services/sumExerciseDurationsService";
import {
  validateExerciseDurationSum,
} from "../validations/validateExerciseSelection";

// Exige login de treinador; o service confere a conta e se os exercícios
// são dele.
export const sumExerciseDurations = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireRole(request, ROLES.trainer);
      const ids = validateExerciseDurationSum(request.data);
      return await sumExerciseDurationsService(user.uid, ids);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
