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
// Alteração: Endpoint que gera a URL de envio de PDF do treinador.
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
  createTrainerAttachmentUploadService,
} from "../services/trainerAttachmentService";
import {
  validateAttachmentUpload,
} from "../validations/validateTrainerAttachment";

export const createTrainerAttachmentUpload = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      // Exige login e role trainer.
      const user = requireRole(request, ROLES.trainer);
      const input = validateAttachmentUpload(request.data);
      return await createTrainerAttachmentUploadService(user.uid, input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
