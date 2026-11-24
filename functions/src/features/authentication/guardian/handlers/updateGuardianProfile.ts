// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para editar o perfil do responsável.
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
  updateGuardianProfileService,
} from "../services/updateGuardianProfileService";
import type {UpdateGuardianProfileResult} from "../types";
import {
  validateGuardianProfileUpdate,
} from "../validations/validateGuardianProfile";

// Exige login e role guardian. O perfil editado é sempre o do token
// verificado (request.auth), nunca um ID enviado pelo cliente.
export const updateGuardianProfile = onCall(
  defaultFunctionOptions,
  async (request): Promise<UpdateGuardianProfileResult> => {
    try {
      const user = requireRole(request, ROLES.guardian);
      const input = validateGuardianProfileUpdate(request.data);
      return await updateGuardianProfileService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
