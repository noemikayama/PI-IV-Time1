// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 07/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para cadastrar exercícios.
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
import {registerExerciseService} from "../services/registerExerciseService";
import {
  validateExerciseRegistration,
} from "../validations/validateExercise";

// Exige login de treinador; o service confere a situação profissional e o
// vínculo com o cavalo.
export const registerExercise = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireRole(request, ROLES.trainer);
      const input = validateExerciseRegistration(request.data);
      return await registerExerciseService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
