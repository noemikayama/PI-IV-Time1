// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipo da consulta leve da conta.
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Itens de 'cavalos' e 'clientes' tipados pela feature de
// cavalos, que mantém as duas listas.
//
// Data: 29/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos da edição do perfil do treinador.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Anexos em PDF: caminhos de experiência (1) e certificações.
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

import type {AccountRef, TrainerHorseRef} from "../../../horses";
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

export type TrainerRegistrationInput = Credentials & {
    modalidades: string[];
    regioesAtendimento: ServiceRegion[];
};

export type AttachmentType = "experiencias" | "certificacoes";

// Formato enviado ao app: caminho (formato do DD) e URL assinada de leitura.
export type TrainerAttachmentView = {
    caminho: string;
    url: string;
};

export type AttachmentUploadInput = {
    tipo: AttachmentType;
};

// Usado para confirmar o envio e para remover um arquivo.
export type AttachmentFileInput = {
    tipo: AttachmentType;
    caminho: string;
};

export type AttachmentUploadResult = {
    caminho: string;
    uploadUrl: string;
    headers: Record<string, string>;
};

// _id é o UID do Firebase Authentication.
export type TrainerDocument = {
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
    // Caminhos no Storage ('/arquivos/treinadores/<uid>/...pdf').
    experiencias: string | null;
    certificacoes: string[];
    regioesAtendimento: ServiceRegion[];
    // Mantidas pela feature de cavalos (DD 5.2).
    cavalos: TrainerHorseRef[];
    clientes: AccountRef[];
    criadoEm: Date;
    atualizadoEm: Date;
};

// Dados enviados ao repository; o 'codigo' é gerado na própria inserção.
export type NewTrainer = Omit<TrainerDocument, "codigo">;

export type TrainerRegistrationResult = {
    id: string;
    codigo: number;
    email: string;
};

// Datas viram string ISO: o callable não serializa 'Date'.
export type TrainerProfile = Omit<
  TrainerDocument,
  "criadoEm" | "atualizadoEm" | "experiencias" | "certificacoes"
> & {
    experiencias: TrainerAttachmentView | null;
    certificacoes: TrainerAttachmentView[];
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

// Projeção usada para conferir a conta e referenciá-la.
export type TrainerAccount = Pick<
    TrainerDocument,
    "_id" | "codigo" | "nome" | "situacaoProfissional"
>;

export type TrainerHomeSource = Pick<
    TrainerDocument,
    "nome" | "situacaoProfissional" | "cavalos" | "clientes"
>;

// Somente os campos enviados pelo app; campo ausente não é alterado.
// O nome completo já vem composto a partir do nome e do sobrenome.
// O envio de PDFs continua em createTrainerAttachmentUpload e
// confirmTrainerAttachment; aqui os anexos só podem ser removidos.
export type UpdateTrainerProfileInput = {
    nome?: string;
    regioesAtendimento?: {
        adicionar: ServiceRegion[];
        remover: ServiceRegion[];
    };
    experiencias?: {remover: string};
    certificacoes?: {remover: string[]};
};

// Alterações já conferidas com o documento atual, enviadas ao repository.
// 'regioesAtendimento' é a lista final; os anexos são os caminhos a remover.
export type TrainerProfileChanges = {
    nome?: string;
    regioesAtendimento?: ServiceRegion[];
    removerExperiencia?: string;
    removerCertificacoes: string[];
};

// Campos editáveis no formato de getTrainerProfile.
export type UpdateTrainerProfileResult = Pick<
  TrainerProfile,
  | "nome"
  | "experiencias"
  | "certificacoes"
  | "regioesAtendimento"
  | "atualizadoEm"
>;
