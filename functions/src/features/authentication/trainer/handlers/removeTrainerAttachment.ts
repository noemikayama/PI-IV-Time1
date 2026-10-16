// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint que remove um PDF do treinador.
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
  removeTrainerAttachmentService,
} from "../services/trainerAttachmentService";
import {
  validateAttachmentRemoval,
} from "../validations/validateTrainerAttachment";

export const removeTrainerAttachment = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      // Exige login e role trainer.
      const user = requireRole(request, ROLES.trainer);
      const input = validateAttachmentRemoval(request.data);
      return await removeTrainerAttachmentService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
