// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Definição dos tipos de login
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Definição dos tipos de conta, credenciais e reserva de e-mail.
// -----------------------------------------------------------------------------

import type {Role} from "../../../../shared/constants/roles";

export type AccountType = "RESPONSAVEL" | "TREINADOR";

export type Credentials = {
    nome: string;
    email: string;
    senha: string;
};

// Documento da coleção 'emails': o e-mail em minúsculas é o próprio _id.
// 'usuarioId' é o _id do usuário (UID do Firebase) na coleção da conta.
export type EmailReservation = {
    _id: string;
    codigo: number;
    tipoConta: AccountType;
    usuarioId: string;
    criadoEm: Date;
};

export type LoginInput = Pick<Credentials, "email" | "senha">;

// Resposta mínima: o necessário para autenticar e escolher a home.
export type LoginResult = {
    // Para o app chamar signInWithCustomToken().
    customToken: string;
    role: Role;
    nome: string;
};

// Conta localizada pelo UID do Firebase, em responsaveis ou treinadores.
export type AccountLookup = {
    role: Role;
    nome: string;
    active: boolean;
};
