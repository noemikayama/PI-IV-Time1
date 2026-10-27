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
// Alteração: Endpoint que confirma o PDF enviado ao Storage.
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
  confirmTrainerAttachmentService,
} from "../services/trainerAttachmentService";
import {
  validateAttachmentConfirm,
} from "../validations/validateTrainerAttachment";

export const confirmTrainerAttachment = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      // Exige login e role trainer.
      const user = requireRole(request, ROLES.trainer);
      const input = validateAttachmentConfirm(request.data);
      return await confirmTrainerAttachmentService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
