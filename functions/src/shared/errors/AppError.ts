// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação de erro próprio da aplicação.
// -----------------------------------------------------------------------------

// Códigos compatíveis com os erros das Cloud Functions (HttpsError).
export type AppErrorCode =
    | "invalid-argument"
    | "already-exists"
    | "unauthenticated"
    | "permission-denied"
    | "not-found"
    | "internal";

/** Erro de domínio com código compatível com o HttpsError. */
export class AppError extends Error {
  readonly code: AppErrorCode;

  /** Cria o erro com o código e a mensagem informados.
   * @param {AppErrorCode} code Código do erro.
   * @param {string} message Mensagem do erro.
   */
  constructor(code: AppErrorCode, message: string) {
    super(message);
    this.name = "AppError";
    this.code = code;
  }
}
