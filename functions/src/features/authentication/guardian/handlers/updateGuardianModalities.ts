// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para editar as modalidades do responsável.
// -----------------------------------------------------------------------------

import {onCall} from "firebase-functions/v2/https";
import {
  defaultFunctionOptions,
} from "../../../../shared/config/functionOptions";
import {ROLES} from "../../../../shared/constants/roles";
import {
  mapErrorToHttpsError,
} from "../../../../shared/errors/mapErrorToHttpsErrors";
import {requireRole} from "../../../../shared/middleware/requireRole";
import {
  updateGuardianModalitiesService,
} from "../services/updateGuardianModalitiesService";
import {
  validateGuardianModalities,
} from "../validations/validateGuardianModalities";

export const updateGuardianModalities = onCall(defaultFunctionOptions,
  async (request) => {
    try {
      // exige login e role guardian; o responsável só edita o próprio perfil
      const user = requireRole(request, ROLES.guardian);
      const input = validateGuardianModalities(request.data);
      return await updateGuardianModalitiesService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  });
