// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Callable da consulta do treino agendado.
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
  getTrainingRecordService,
} from "../services/getTrainingRecordService";
import {
  validateTrainingRecordInput,
} from "../validations/validateTrainingRecord";

// Exige só o login: o service confere a conta, o acesso ao treino (quem não
// tem acesso recebe not-found) e calcula as ações permitidas.
export const getTrainingRecord = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireAuthentication(request);
      const input = validateTrainingRecordInput(request.data);
      return await getTrainingRecordService(user, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
