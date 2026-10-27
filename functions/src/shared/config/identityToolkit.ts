// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Extração da URL do Identity Toolkit usada no login para
// reaproveitamento na recuperação de senha.
// -----------------------------------------------------------------------------

import {WEB_API_KEY} from "./environment";

/** Monta a URL de um método de contas do Identity Toolkit, usando o emulador
 * do Authentication quando ele estiver configurado.
 * @param {string} method Método da API, como 'signInWithPassword'.
 * @return {string} URL completa, incluindo a chave da API.
 */
export function identityToolkitUrl(method: string): string {
  const emulatorHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const baseUrl = emulatorHost ?
    `http://${emulatorHost}/identitytoolkit.googleapis.com` :
    "https://identitytoolkit.googleapis.com";

  return `${baseUrl}/v1/accounts:${method}?key=${WEB_API_KEY.value()}`;
}
