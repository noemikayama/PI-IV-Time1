// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Callable do registro da execução do treino.
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
  registerTrainingExecutionService,
} from "../services/registerTrainingExecutionService";
import {
  validateExecution,
} from "../validations/validateExecution";

// Exige só o login: o papel é conferido no service, depois do acesso, para
// quem vê o treino receber a mensagem de que só o atleta registra a
// execução, e quem não vê receber not-found.
export const registerTrainingExecution = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireAuthentication(request);
      const input = validateExecution(request.data);
      return await registerTrainingExecutionService(user, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
