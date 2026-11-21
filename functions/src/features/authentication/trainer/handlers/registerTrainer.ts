// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do endpoint callable para cadastrar treinadores.
// -----------------------------------------------------------------------------

import {onCall} from "firebase-functions/v2/https";
import {
  defaultFunctionOptions,
} from "../../../../shared/config/functionOptions";
import {
  mapErrorToHttpsError,
} from "../../../../shared/errors/mapErrorToHttpsErrors";
import {
  registerTrainerService,
} from "../services/registerTrainerService";
import {
  validateTrainerRegistration,
} from "../validations/validateTrainerRegistration";

// Cadastro público, não exige autenticação.
export const registerTrainer = onCall(
  defaultFunctionOptions,
  async (request) => {
    try {
      const input = validateTrainerRegistration(request.data);
      return await registerTrainerService(input);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
