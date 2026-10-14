// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Definição dos tipos de conta, credenciais e reserva de e-mail.
// ----------------------------------------------------------------------------- 

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
