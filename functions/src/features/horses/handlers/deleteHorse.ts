// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para excluir o cavalo.
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
import {deleteHorseService} from "../services/deleteHorseService";
import {validateHorseId} from "../validations/validateHorse";

// Exige login de responsável; o service confere se ele é o proprietário.
export const deleteHorse = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireRole(request, ROLES.guardian);
      const id = validateHorseId(request.data);
      return await deleteHorseService(user.uid, id);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
