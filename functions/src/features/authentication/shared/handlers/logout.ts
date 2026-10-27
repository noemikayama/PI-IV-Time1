// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação da função de logout
// -----------------------------------------------------------------------------

import {onCall} from "firebase-functions/v2/https";
import {
  defaultFunctionOptions,
} from "../../../../shared/config/functionOptions";
import {
  mapErrorToHttpsError,
} from "../../../../shared/errors/mapErrorToHttpsErrors";
import {
  requireAuthentication,
} from "../../../../shared/middleware/requireAuthentication";
import {revokeUserSessions} from "../services/logoutService";
import type {LogoutResult} from "../types";

// Exige autenticação e não lê o corpo da requisição: o usuário que terá os
// tokens revogados é sempre o do token verificado (request.auth), nunca um
// UID informado pelo cliente. Atende os dois perfis, então não usa requireRole.
export const logout = onCall(
  defaultFunctionOptions,
  async (request): Promise<LogoutResult> => {
    try {
      const user = requireAuthentication(request);
      return await revokeUserSessions(user.uid);
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
