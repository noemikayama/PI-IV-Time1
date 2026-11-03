// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint que confirma a imagem enviada ao Storage.
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
import {confirmHorseImageService} from "../services/horseImageService";
import {
  validateHorseImageFile,
} from "../validations/validateHorseImage";

// Exige login de responsável; o service confere se ele é o proprietário.
export const confirmHorseImage = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireRole(request, ROLES.guardian);
      const input = validateHorseImageFile(request.data);
      return await confirmHorseImageService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
