// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Callable do registro do feedback do treinador.
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
  registerTrainingFeedbackService,
} from "../services/registerTrainingFeedbackService";
import {
  validateFeedback,
} from "../validations/validateFeedback";

// Exige só o login: o papel é conferido no service, depois do acesso, como
// no registro da execução.
export const registerTrainingFeedback = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireAuthentication(request);
      const input = validateFeedback(request.data);
      return await registerTrainingFeedbackService(user, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
