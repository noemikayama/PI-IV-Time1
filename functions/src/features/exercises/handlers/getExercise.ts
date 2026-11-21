// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Endpoint callable dos detalhes do exercício.
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
import {getExerciseService} from "../services/getExerciseService";
import {validateExerciseLookup} from "../validations/validateExercise";

const ALLOWED_ROLES: readonly string[] = [ROLES.guardian, ROLES.trainer];

// Exige login de treinador ou de responsável. O perfil é conferido antes da
// validação, como o requireRole faz nas outras callables; o service confere
// a conta e o acesso pelo vínculo com os cavalos do exercício.
export const getExercise = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireAuthentication(request);
      if (!ALLOWED_ROLES.includes(user.role ?? "")) {
        throw new AppError(
          "permission-denied",
          "Acesso não permitido para este perfil."
        );
      }
      const lookup = validateExerciseLookup(request.data);
      return await getExerciseService(user, lookup);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
