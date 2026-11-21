// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Endpoint callable para listar as modalidades.
// -----------------------------------------------------------------------------

import {onCall} from "firebase-functions/v2/https";
import {
  defaultFunctionOptions,
} from "../../../shared/config/functionOptions";
import {
  mapErrorToHttpsError,
} from "../../../shared/errors/mapErrorToHttpsErrors";
import {getModalitiesService} from "../services/getModalitiesService";

// Consulta pública, não exige autenticação: o cadastro do treinador precisa
// das modalidades antes de existir login.
export const getModalities = onCall(
  defaultFunctionOptions,
  async () => {
    try {
      return await getModalitiesService();
    } catch (error) {
      throw mapErrorToHttpsError(error);
    }
  }
);
