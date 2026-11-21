// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Extração da checagem de código de erro do Firebase, antes
// duplicada em authAccountService e logoutService.
// -----------------------------------------------------------------------------

/** Verifica se o erro contém o código solicitado.
 * @param {unknown} error Erro recebido.
 * @param {string} code Código procurado.
 * @return {boolean} Indica se os códigos correspondem.
 */
export function hasFirebaseErrorCode(error: unknown, code: string): boolean {
  return typeof error === "object" && error !== null &&
        (error as {code?: unknown}).code === code;
}
