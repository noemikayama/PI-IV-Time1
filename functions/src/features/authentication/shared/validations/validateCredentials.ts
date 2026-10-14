// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação e normalização dos dados comuns de cadastro.
// ----------------------------------------------------------------------------- 

import {AppError} from "../../../../shared/errors/AppError";
import type {Credentials} from "../types";

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function invalid(message: string): AppError {
    return new AppError("invalid-argument", message);
}

export function asRecord(data: unknown): Record<string, unknown> {
    if (typeof data !== "object" || data === null || Array.isArray(data)) {
        throw invalid("Dados de cadastro inválidos.");
    }
    return data as Record<string, unknown>;
}

// Valida e normaliza nome, e-mail e senha (comuns a responsável e treinador).
export function parseCredentials(data: Record<string, unknown>): Credentials {
    const {nome, email, senha} = data;

    if (typeof nome !== "string" || nome.trim().length < 3 || nome.trim().length > 120) {
        throw invalid("O nome deve ter entre 3 e 120 caracteres.");
    }
    if (typeof email !== "string" || email.length > 254 || !EMAIL_PATTERN.test(email.trim())) {
        throw invalid("E-mail inválido.");
    }
    if (typeof senha !== "string" || senha.length < 8 || senha.length > 128) {
        throw invalid("A senha deve ter entre 8 e 128 caracteres.");
    }

    return {
        nome: nome.trim(),
        email: email.trim().toLowerCase(),
        senha,
    };
}
