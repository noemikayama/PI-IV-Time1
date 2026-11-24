// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: _id dos cavalos e das modalidades do perfil como string
// hexadecimal.
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipo da consulta leve da conta.
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Itens de 'cavalos' tipados por GuardianHorseRef (feature de
// cavalos, que mantém a lista).
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos da edição do perfil do responsável.
//
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos da edição das modalidades do responsável.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Padronização do formato.
//
// Data: 14/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Acréscimo dos tipos usados na home.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Definição dos tipos usados no cadastro de responsáveis.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import type {GuardianHorseRef} from "../../../horses";
import type {Credentials} from "../../shared";
import type {
  StatusRegistroHome,
  Progresso,
  RefResumo,
} from "../../shared/types/home";

export type GuardianRegistrationInput = Credentials;

// _id é o UID do Firebase Authentication.
export type GuardianDocument = {
    _id: string;
    codigo: number;
    nome: string;
    email: string;
    situacaoCadastral: "ATIVO" | "INATIVO";
    // Mantida pela feature de cavalos (DD 5.2).
    cavalos: GuardianHorseRef[];
    modalidades: {_id: ObjectId; codigo: number; nome: string}[];
    criadoEm: Date;
    atualizadoEm: Date;
};

// Vínculo com a coleção 'modalidades': _id referencia a modalidade e
// 'codigo'/'nome' são cópia do catálogo no momento da gravação.
export type GuardianModality = GuardianDocument["modalidades"][number];

// Dados enviados ao repository; o 'codigo' é gerado na própria inserção.
export type NewGuardian = Omit<GuardianDocument, "codigo">;

export type GuardianRegistrationResult = {
    id: string;
    codigo: number;
    email: string;
};

// Datas viram string ISO e ObjectId vira string hexadecimal: o callable não
// serializa 'Date' nem 'ObjectId'.
export type GuardianProfile = Omit<
  GuardianDocument,
  "criadoEm" | "atualizadoEm" | "cavalos" | "modalidades"
> & {
    cavalos: {
        _id: string;
        codigo: string;
        nome: string;
        responsabilidades: string[];
    }[];
    modalidades: {_id: string; codigo: number; nome: string}[];
    criadoEm: string;
    atualizadoEm: string;
};

export interface TreinoDiaResponsavel {
    registroId: string;
    nomeTreino: string; // Cabeçalho do card de treinamento do registro.
    nomeCavalo: string;
    nomeTreinador: string;
    duracaoMinutos: number;
    nomePlano: string;
    status: StatusRegistroHome;
}

export interface HomeResponsavel {
    tipoConta: "RESPONSAVEL";
    nome: string;
    totalCavalos: number; // Usado na sidebar: animais cadastrados.
    treinosDoDia: TreinoDiaResponsavel[];
    treinosSemana: Progresso;
    treinosMes: Progresso;
    treinosTotal: number; // Treinos REALIZADO + PARCIAL desde sempre.
    cavalos: RefResumo[]; // Prévia limitada; lista completa em "Mostrar tudo".
    treinadores: RefResumo[];
}

// Projeção usada para conferir a conta e referenciá-la.
export type GuardianAccount = Pick<
    GuardianDocument,
    "_id" | "codigo" | "nome" | "situacaoCadastral"
>;

export type GuardianHomeSource = Pick<
    GuardianDocument,
    "nome" | "situacaoCadastral" | "cavalos"
>;

// IDs únicos, já convertidos para ObjectId, na ordem informada.
export type UpdateGuardianModalitiesInput = {
    modalidadeIds: ObjectId[];
};

// Formato enviado ao app: o ObjectId vira string.
export type UpdateGuardianModalitiesResult = {
    modalidades: {id: string; codigo: number; nome: string}[];
};

// Nome completo já composto a partir do nome e do sobrenome enviados pelo app.
export type UpdateGuardianProfileInput = {
    nome: string;
};

// Nome gravado e data da última alteração, no formato do app.
export type UpdateGuardianProfileResult = {
    nome: string;
    atualizadoEm: string;
};
