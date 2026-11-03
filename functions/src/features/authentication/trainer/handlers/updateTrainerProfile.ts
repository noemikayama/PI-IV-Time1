// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 29/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para editar o perfil do treinador.
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
  updateTrainerProfileService,
} from "../services/updateTrainerProfileService";
import type {UpdateTrainerProfileResult} from "../types";
import {
  validateTrainerProfileUpdate,
} from "../validations/validateTrainerProfile";

// Exige login e role trainer. O perfil editado é sempre o do token
// verificado (request.auth), nunca um ID enviado pelo cliente.
export const updateTrainerProfile = onCall(
  defaultFunctionOptions,
  async (request): Promise<UpdateTrainerProfileResult> => {
    try {
      const user = requireRole(request, ROLES.trainer);
      const input = validateTrainerProfileUpdate(request.data);
      return await updateTrainerProfileService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
