// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação de um erro da aplicação com código e mensagem próprios.
// ----------------------------------------------------------------------------- 

// Códigos compatíveis com os códigos de erro das Cloud Functions (HttpsError).
export type AppErrorCode =
    | "invalid-argument"
    | "already-exists"
    | "unauthenticated"
    | "permission-denied"
    | "not-found"
    | "internal";

export class AppError extends Error {
    readonly code: AppErrorCode;

    constructor(code: AppErrorCode, message: string) {
        super(message);
        this.name = "AppError";
        this.code = code;
    }
}
