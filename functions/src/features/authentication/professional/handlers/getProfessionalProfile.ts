// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para obter o perfil de um treinador.
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
  getProfessionalProfileService,
} from "../services/getProfessionalProfileService";

export const getProfessionalProfile = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      // Exige login e role professional.
      const user = requireRole(request, ROLES.professional);
      return await getProfessionalProfileService(user.uid);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
