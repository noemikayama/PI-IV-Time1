// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação dos dados enviados no cadastro de treinadores.
// ----------------------------------------------------------------------------- 

import {AppError} from "../../../../shared/errors/AppError";
import {asRecord, parseCredentials} from "../../shared";
import type {ProfessionalRegistrationInput, ServiceRegion} from "../types";

function invalid(message: string): AppError {
    return new AppError("invalid-argument", message);
}

function parseModalidades(value: unknown): string[] {
    if (value === undefined) return [];
    if (!Array.isArray(value) || value.length > 20) {
        throw invalid("Modalidades inválidas.");
    }
    return value.map((item) => {
        if (typeof item !== "string" || item.trim() === "" || item.length > 60) {
            throw invalid("Modalidades inválidas.");
        }
            return item.trim();
    });
}

function parseRegioes(value: unknown): ServiceRegion[] {
    if (value === undefined) return [];
    if (!Array.isArray(value) || value.length > 30) {
        throw invalid("Regiões de atendimento inválidas.");
    }
    return value.map((item) => {
        const region = asRecord(item);
        const {estado, cidade, complemento} = region;

        if (typeof estado !== "string" || !/^[A-Z]{2}$/.test(estado)) {
            throw invalid("O estado deve ser a sigla com 2 letras maiúsculas.");
        }
        if (typeof cidade !== "string" || cidade.trim() === "" || cidade.length > 100) {
            throw invalid("Cidade inválida.");
        }
        if (complemento === undefined) return {estado, cidade: cidade.trim()};
        if (typeof complemento !== "string" || complemento.trim() === "" || complemento.length > 150) {
            throw invalid("Complemento inválido.");
        }
        return {estado, cidade: cidade.trim(), complemento: complemento.trim()};
    });
}

export function validateProfessionalRegistration(data: unknown): ProfessionalRegistrationInput {
    const record = asRecord(data);
    return {
        ...parseCredentials(record),
        modalidades: parseModalidades(record.modalidades),
        regioesAtendimento: parseRegioes(record.regioesAtendimento),
    };
}
