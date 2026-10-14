// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Definição dos tipos usados no cadastro de responsáveis.
// ----------------------------------------------------------------------------- 

import type {ObjectId} from "mongodb";
import type {Credentials} from "../../shared";

export type GuardianRegistrationInput = Credentials;

// _id é o UID do Firebase Authentication.
export type GuardianDocument = {
    _id: string;
    codigo: number;
    nome: string;
    email: string;
    situacaoCadastral: "ATIVO" | "INATIVO";
    cavalos: {
        _id: ObjectId;
        codigo: string;
        nome: string;
        responsabilidades: string[];
    }[];
    modalidades: {_id: ObjectId; codigo: number; nome: string}[];
    criadoEm: Date;
    atualizadoEm: Date;
};

// Dados enviados ao repository; o 'codigo' é gerado na própria inserção.
export type NewGuardian = Omit<GuardianDocument, "codigo">;

export type GuardianRegistrationResult = {
    id: string;
    codigo: number;
    email: string;
};

export type GuardianProfile = Omit<GuardianDocument, "criadoEm" | "atualizadoEm"> & {
    criadoEm: string;
    atualizadoEm: string;
};
