// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
// Alteração: Definição dos tipos usados no cadastro de treinadores.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import type {Credentials} from "../../shared";
import type {
  StatusRegistroHome,
  Progresso,
  RefResumo,
} from "../../shared/types/home";

export type ServiceRegion = {
    estado: string;
    cidade: string;
    complemento?: string;
};

export type ProfessionalRegistrationInput = Credentials & {
    modalidades: string[];
    regioesAtendimento: ServiceRegion[];
};

// _id é o UID do Firebase Authentication.
export type ProfessionalDocument = {
    _id: string;
    codigo: number;
    nome: string;
    email: string;
    situacaoProfissional:
      | "DISPONIVEL"
      | "AFASTADO"
      | "INDISPONIVEL"
      | "INATIVO";
    modalidades: string[];
    experiencias: string[];
    certificacoes: string[];
    regioesAtendimento: ServiceRegion[];
    cavalos: {_id: ObjectId; codigo: string; nome: string}[];
    clientes: {_id: string; codigo: number; nome: string}[];
    criadoEm: Date;
    atualizadoEm: Date;
};

// Dados enviados ao repository; o 'codigo' é gerado na própria inserção.
export type NewProfessional = Omit<ProfessionalDocument, "codigo">;

export type ProfessionalRegistrationResult = {
    id: string;
    codigo: number;
    email: string;
};

// Datas viram string ISO: o callable não serializa 'Date'.
export type ProfessionalProfile = Omit<
  ProfessionalDocument,
  "criadoEm" | "atualizadoEm"
> & {
    criadoEm: string;
    atualizadoEm: string;
};

export interface TreinoDiaTreinador {
    registroId: string;
    nomeTreino: string;
    nomeCavalo: string;
    nomePlano: string;
    status: StatusRegistroHome;
}

export interface HomeTreinador {
    tipoConta: "TREINADOR";
    nome: string;
    totalCavalos: number; // Sidebar: animais vinculados.
    treinosDoDia: TreinoDiaTreinador[];
    // feitos = sessões da semana com feedback; total = sessões executadas
    // na semana.
    feedbacksSemana: Progresso;
    treinosSemana: Progresso;
    totalExercicios: number;
    cavalos: RefResumo[];
    clientes: RefResumo[];
}

export type ProfessionalHomeSource = Pick<
    ProfessionalDocument,
    "nome" | "situacaoProfissional" | "cavalos" | "clientes"
>;
