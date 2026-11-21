// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Endpoint callable que confere o microchip no servidor Java, para
// a etapa do microchip no cadastro de cavalos.
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
import {asRecord} from "../../authentication/shared";
import {assertValidMicrochip} from "../services/microchipServer";
import {parseMicrochip} from "../validations/validateHorse";

// Exige login de responsável. Confere o formato e, com o servidor Java
// configurado, o país e os dígitos verificadores. A unicidade não é
// conferida aqui: o registerHorse retorna 'already-exists'.
export const validateMicrochip = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      requireRole(request, ROLES.guardian);
      const codigo = parseMicrochip(asRecord(request.data).codigo);
      await assertValidMicrochip(codigo);
      return {valido: true};
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
