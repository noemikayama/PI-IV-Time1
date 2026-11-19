// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Microchip conferido no servidor Java antes do cadastro.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para cadastrar cavalos.
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
import {assertValidMicrochip} from "../services/microchipServer";
import {registerHorseService} from "../services/registerHorseService";
import {validateHorseRegistration} from "../validations/validateHorse";

// Exige login de responsável; o service confere se ele é o proprietário.
// O microchip passa pelo servidor Java (quando configurado) antes de gravar.
export const registerHorse = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireRole(request, ROLES.guardian);
      const input = validateHorseRegistration(request.data);
      await assertValidMicrochip(input.codigo);
      return await registerHorseService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
