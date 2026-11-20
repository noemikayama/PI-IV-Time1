// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable da galeria de exercícios.
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
  listExerciseGalleryService,
} from "../services/listExerciseGalleryService";
import {
  validateExerciseGallery,
} from "../validations/validateExerciseSelection";

// Exige login de treinador; o service confere a conta e o vínculo com o
// cavalo do filtro.
export const listExerciseGallery = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireRole(request, ROLES.trainer);
      const input = validateExerciseGallery(request.data);
      return await listExerciseGalleryService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
