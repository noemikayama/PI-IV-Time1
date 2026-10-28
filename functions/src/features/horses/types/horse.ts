// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos do envio, da confirmação e da remoção de imagens.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos do documento, do cadastro, da edição e da consulta.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipo da referência resumida de treinador.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";

// Referência resumida a um treinador dentro de cavalos.treinadores.
export type HorseTrainerRef = {_id: string; nome: string};

export type HorseSex = "MACHO" | "FEMEA";

export type HorseResponsibility = "PROPRIETARIO" | "ATLETA";

// Registro de lesão (historicoLesoes). Datas em AAAA-MM-DD.
export type InjuryRecord = {
    data: string;
    descricao: string;
    prescricao?: string;
};

// Referência resumida a um responsável (proprietario e atleta).
export type GuardianRef = {_id: string; codigo: number; nome: string};

// Coleção 'cavalos'. 'codigo' é o microchip (15 dígitos, único).
export type HorseDocument = {
    _id: ObjectId;
    codigo: string;
    nome: string;
    // A idade não é armazenada: é calculada a partir desta data.
    dataNascimento: string;
    raca: string;
    pelagem: string;
    sexo: HorseSex;
    // Caminhos no Storage (formato do DD), na ordem de envio.
    imagens: string[];
    modalidade?: {_id: ObjectId; codigo: number; nome: string};
    limitacoesFisicas: string[];
    observacoesSaude: string[];
    // Ordem decrescente de data (a primeira é a mais recente).
    historicoLesoes: InjuryRecord[];
    situacaoCadastral: "ATIVO" | "INATIVO";
    proprietario: GuardianRef;
    // Omitido enquanto o proprietário não for também o atleta.
    atleta?: GuardianRef;
    treinadores: {_id: string; codigo: number; nome: string}[];
    planoAtual?: {_id: ObjectId; codigo: number; titulo: string};
    avaliacoes: {
        _id: ObjectId;
        codigo: number;
        data: string;
        treinador: {_id: string; codigo: number; nome: string};
    }[];
    criadoEm: Date;
    atualizadoEm: Date;
};

// Item de responsaveis.cavalos.
export type GuardianHorseRef = {
    _id: ObjectId;
    codigo: string;
    nome: string;
    responsabilidades: HorseResponsibility[];
};

// Campos informados no cadastro e alteráveis na edição.
export type HorseDetailsInput = {
    nome: string;
    dataNascimento: string;
    raca: string;
    pelagem: string;
    sexo: HorseSex;
    modalidadeId: ObjectId | null;
    limitacoesFisicas: string[];
    observacoesSaude: string[];
    historicoLesoes: InjuryRecord[];
};

export type HorseRegistrationInput = HorseDetailsInput & {
    codigo: string;
    responsabilidades: HorseResponsibility[];
};

// Apenas os campos enviados são alterados; modalidadeId null remove a
// modalidade.
export type HorseUpdateInput = {
    id: ObjectId;
    changes: Partial<HorseDetailsInput>;
};

export type HorseRegistrationResult = {
    id: string;
    codigo: string;
    nome: string;
};

export type HorseAge = {anos: number; meses: number};

export type HorseImageContentType = "image/jpeg" | "image/png";

// Formato enviado ao app: caminho (formato do DD) e URL assinada de leitura.
export type HorseImageView = {
    caminho: string;
    url: string;
};

export type HorseImageUploadInput = {
    id: ObjectId;
    contentType: HorseImageContentType;
};

// Usado para confirmar o envio e para remover uma imagem.
export type HorseImageFileInput = {
    id: ObjectId;
    caminho: string;
};

export type HorseImageUploadResult = {
    caminho: string;
    uploadUrl: string;
    headers: Record<string, string>;
};

// Referência enviada ao app: o ObjectId vira string.
type RefView = {id: string; codigo: number; nome: string};

// Formato enviado ao app. Datas de controle viram string ISO.
export type HorseView = {
    id: string;
    codigo: string;
    nome: string;
    dataNascimento: string;
    idade: HorseAge;
    raca: string;
    pelagem: string;
    sexo: HorseSex;
    imagens: HorseImageView[];
    modalidade: RefView | null;
    limitacoesFisicas: string[];
    observacoesSaude: string[];
    historicoLesoes: InjuryRecord[];
    situacaoCadastral: "ATIVO" | "INATIVO";
    proprietario: RefView;
    atleta: RefView | null;
    treinadores: RefView[];
    planoAtual: {id: string; codigo: number; titulo: string} | null;
    avaliacoes: {
        id: string;
        codigo: number;
        data: string;
        treinador: RefView;
    }[];
    // Responsabilidades de quem consulta (vazio para o treinador).
    responsabilidades: HorseResponsibility[];
    criadoEm: string;
    atualizadoEm: string;
};
