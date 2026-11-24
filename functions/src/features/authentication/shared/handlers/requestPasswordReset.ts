// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação da função de recuperação de senha
// -----------------------------------------------------------------------------

import {onCall} from "firebase-functions/v2/https";
import {
  defaultFunctionOptions,
} from "../../../../shared/config/functionOptions";
import {
  mapErrorToHttpsError,
} from "../../../../shared/errors/mapErrorToHttpsErrors";
import {sendPasswordReset} from "../services/passwordResetService";
import type {PasswordResetResult} from "../types";
import {
  validatePasswordResetInput,
} from "../validations/validateCredentials";

// Recuperação pública, não exige autenticação. Recebe apenas { email }.
export const requestPasswordReset = onCall(
  defaultFunctionOptions,
  async (request): Promise<PasswordResetResult> => {
    try {
      return await sendPasswordReset(validatePasswordResetInput(request.data));
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
