// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do middleware de autenticação.
// ----------------------------------------------------------------------------- 

import type {CallableRequest} from "firebase-functions/v2/https";
import {AppError} from "../errors/AppError";

export type AuthenticatedUser = {
    uid: string;
    role?: string;
};

// Exige token válido do Firebase Auth e devolve o contexto do usuário.
export function requireAuthentication(request: CallableRequest): AuthenticatedUser {
    if (!request.auth) {
        throw new AppError("unauthenticated", "Faça login para continuar.");
    }
    const role = request.auth.token.role;
    return {
        uid: request.auth.uid,
        role: typeof role === "string" ? role : undefined,
    };
}
