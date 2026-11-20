// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable da agenda de treinos.
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
  getGuardianAgenda,
  getTrainerAgenda,
} from "../services/getTrainingAgendaService";
import type {AgendaResult} from "../types";
import {validateAgendaInput} from "../validations/validateAgendaInput";

// Atende os dois perfis, então usa requireAuthentication e escolhe a agenda
// pelo role, como em getHome.
export const getTrainingAgenda = onCall(
  defaultFunctionOptions,
  async (request): Promise<AgendaResult> => {
    try {
      const user = requireAuthentication(request);
      // Um único "agora" para a semana padrão, os planos e o campo 'hoje'.
      const now = new Date();
      const filtro = validateAgendaInput(request.data, now);

      switch (user.role) {
      case ROLES.guardian:
        return await getGuardianAgenda(user.uid, filtro, now);
      case ROLES.trainer:
        return await getTrainerAgenda(user.uid, filtro, now);
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
