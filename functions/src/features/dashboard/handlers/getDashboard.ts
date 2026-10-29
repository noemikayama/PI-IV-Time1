// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable do dashboard de evolução.
// -----------------------------------------------------------------------------

import {onCall} from "firebase-functions/v2/https";
import {
  defaultFunctionOptions,
} from "../../../shared/config/functionOptions";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {
  mapErrorToHttpsError,
} from "../../../shared/errors/mapErrorToHttpsErrors";
import {
  requireAuthentication,
} from "../../../shared/middleware/requireAuthentication";
import {
  getGuardianDashboard,
} from "../services/getGuardianDashboardService";
import type {DashboardResult} from "../types";
import {
  validateDashboardFilters,
} from "../validations/validateDashboardFilters";

// Atende os dois perfis, então usa requireAuthentication e escolhe o
// dashboard pelo role, como em getHome. O treinador entra aqui quando as
// funções de treino dele existirem.
export const getDashboard = onCall(
  defaultFunctionOptions,
  async (request): Promise<DashboardResult> => {
    try {
      const user = requireAuthentication(request);
      const filtros = validateDashboardFilters(request.data);

      switch (user.role) {
      case ROLES.guardian:
        return await getGuardianDashboard(user.uid, filtros);
      default:
        throw new AppError(
          "permission-denied",
          "Perfil de acesso inválido."
        );
      }
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
