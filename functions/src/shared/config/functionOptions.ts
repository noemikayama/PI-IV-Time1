// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Definição das opções padrão das funções callable.
// -----------------------------------------------------------------------------

import type {CallableOptions} from "firebase-functions/v2/https";
import {mongodbUriSecret, WEB_API_KEY} from "./environment";

// Opções das Cloud Functions callable.
export const defaultFunctionOptions: CallableOptions = {
  region: "southamerica-east1",
  secrets: [mongodbUriSecret, WEB_API_KEY],
  maxInstances: 10,
};
