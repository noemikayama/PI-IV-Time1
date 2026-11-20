// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Microchip alterado é conferido no servidor Java antes de gravar.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para editar cavalos.
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
import {updateHorseService} from "../services/updateHorseService";
import {validateHorseUpdate} from "../validations/validateHorse";

// Exige login de responsável; só o proprietário edita. O Java só é
// consultado quando o microchip é enviado: uma edição sem 'codigo' continua
// valendo para cavalos cadastrados antes dessa conferência.
export const updateHorse = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const user = requireRole(request, ROLES.guardian);
      const input = validateHorseUpdate(request.data);
      if (input.changes.codigo !== undefined) {
        await assertValidMicrochip(input.changes.codigo);
      }
      return await updateHorseService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
