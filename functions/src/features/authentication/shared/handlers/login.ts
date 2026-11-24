// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Correção do import da validação e padronização do formato.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação da função de login
// -----------------------------------------------------------------------------

import {onCall} from "firebase-functions/v2/https";
import {
  defaultFunctionOptions,
} from "../../../../shared/config/functionOptions";
import {
  mapErrorToHttpsError,
} from "../../../../shared/errors/mapErrorToHttpsErrors";
import {authenticateUser} from "../services/authenticateUser";
import type {LoginResult} from "../types";
import {validateLoginInput} from "../validations/validateCredentials";

// Login público, não exige autenticação.
export const login = onCall(
  defaultFunctionOptions,
  async (request): Promise<LoginResult> => {
    try {
      return await authenticateUser(validateLoginInput(request.data));
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
