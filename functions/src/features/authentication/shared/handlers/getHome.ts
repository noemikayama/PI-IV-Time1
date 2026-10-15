// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Padronização do formato e tipos importados por ../types.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação da função de entrada da home
// -----------------------------------------------------------------------------

import {onCall} from "firebase-functions/v2/https";
import {
  defaultFunctionOptions,
} from "../../../../shared/config/functionOptions";
import {ROLES} from "../../../../shared/constants/roles";
import {AppError} from "../../../../shared/errors/AppError";
import {
  mapErrorToHttpsError,
} from "../../../../shared/errors/mapErrorToHttpsErrors";
import {
  requireAuthentication,
} from "../../../../shared/middleware/requireAuthentication";
import {getGuardianHome} from "../../guardian/services/getHomeService";
import {
  getProfessionalHome,
} from "../../professional/services/professionalHomeService";
import type {HomeResult} from "../types";

// Atende os dois perfis, então usa requireAuthentication e escolhe a home
// pelo role (requireRole serve a endpoints de um perfil só).
export const getHome = onCall(
  defaultFunctionOptions,
  async (request): Promise<HomeResult> => {
    try {
      const user = requireAuthentication(request);

      switch (user.role) {
      case ROLES.guardian:
        return await getGuardianHome(user.uid);
      case ROLES.professional:
        return await getProfessionalHome(user.uid);
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
