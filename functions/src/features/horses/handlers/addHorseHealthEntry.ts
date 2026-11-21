// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para incluir saúde ou lesão no cavalo.
// Alteração: Exclusiva do proprietário (login de responsável exigido).
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
  addHorseHealthEntryService,
} from "../services/addHorseHealthEntryService";
import {validateHorseHealthEntry} from "../validations/validateHorse";

// Exige login de responsável; só o proprietário inclui.
export const addHorseHealthEntry = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireRole(request, ROLES.guardian);
      const input = validateHorseHealthEntry(request.data);
      return await addHorseHealthEntryService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
