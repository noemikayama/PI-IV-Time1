// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Callable das execuções que esperam feedback.
// -----------------------------------------------------------------------------

import {onCall} from "firebase-functions/v2/https";
import {
  defaultFunctionOptions,
} from "../../../shared/config/functionOptions";
import {
  mapErrorToHttpsError,
} from "../../../shared/errors/mapErrorToHttpsErrors";
import {ROLES} from "../../../shared/constants/roles";
import {requireRole} from "../../../shared/middleware/requireRole";
import {
  listPendingFeedbacksService,
} from "../services/listPendingFeedbacksService";
import {
  validatePendingFeedbacksInput,
} from "../validations/validateTrainingRecord";

// Só o treinador tem execuções esperando o feedback dele.
export const listPendingFeedbacks = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireRole(request, ROLES.trainer);
      validatePendingFeedbacksInput(request.data);
      return await listPendingFeedbacksService(user);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
