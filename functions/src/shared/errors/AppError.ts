// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Código 'failed-precondition' (ex.: envios ainda em andamento).
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Código failed-precondition, para regras que dependem do
// estado atual.
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
    | "failed-precondition"
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
