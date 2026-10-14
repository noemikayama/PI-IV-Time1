// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação e remoção de contas no Firebase Authentication.
// ----------------------------------------------------------------------------- 

import {logger} from "firebase-functions";
import {auth} from "../../../../shared/config/firebase";
import type {Role} from "../../../../shared/constants/roles";
import {AppError} from "../../../../shared/errors/AppError";
import type {Credentials} from "../types";

function hasCode(error: unknown, code: string): boolean {
    return typeof error === "object" && error !== null &&
        (error as {code?: unknown}).code === code;
}

// Cria o usuário no Firebase Authentication e define a role como custom claim.
// A senha fica somente no Firebase Authentication. Retorna o UID, que será o
// _id do perfil no MongoDB.
export async function createAuthAccount(
    credentials: Credentials,
    role: Role
): Promise<string> {
    try {
        const user = await auth.createUser({
            email: credentials.email,
            password: credentials.senha,
            displayName: credentials.nome,
        });

        try {
            await auth.setCustomUserClaims(user.uid, {role});
        } catch (error) {
            await deleteAuthAccount(user.uid);
            throw error;
        }

        return user.uid;
    } catch (error) {
        if (hasCode(error, "auth/email-already-exists")) {
            throw new AppError("already-exists", "E-mail já cadastrado.");
        }
        throw error;
    }
}

// Remove o usuário se a gravação no MongoDB falhar.
export async function deleteAuthAccount(uid: string): Promise<void> {
    try {
        await auth.deleteUser(uid);
    } catch {
        logger.error("Falha ao reverter usuário do Firebase Authentication", {uid});
    }
}
