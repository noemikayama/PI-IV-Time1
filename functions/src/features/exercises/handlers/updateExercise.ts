// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Endpoint callable da edição do exercício.
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
import {updateExerciseService} from "../services/updateExerciseService";
import {validateExerciseUpdate} from "../validations/validateExercise";

// Exige login de treinador; o service confere a conta, a autoria e o
// vínculo com o cavalo novo.
export const updateExercise = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireRole(request, ROLES.trainer);
      const input = validateExerciseUpdate(request.data);
      return await updateExerciseService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
