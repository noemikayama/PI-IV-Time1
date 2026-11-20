// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Tipos da consulta, da resposta, da edição e do acesso ao
// exercício (visualização e edição).
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipo e cavalo do exercício lidos pelos detalhes do treinamento.
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos da galeria de exercícios e do tempo total da seleção.
//
// Data: 07/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos do documento, do cadastro e das mídias de exercícios.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import type {RefView} from "../../horses";

export type ExercisePrivacy = "GENERICO" | "ESPECIFICO";

export type ExerciseRegistrant = "PLATAFORMA" | "TREINADOR";

// Item de exercicios.materiais.
export type ExerciseMaterial = {
    descricao: string;
    quantidade: number;
};

// Referência resumida ao cavalo dentro de exercicios.cavalo. 'codigo' é o
// microchip.
export type ExerciseHorseRef = {_id: ObjectId; codigo: string; nome: string};

// Referência resumida ao treinador dentro de exercicios.treinador.
export type ExerciseTrainerRef = {_id: string; codigo: number; nome: string};

// Coleção 'exercicios'.
export type ExerciseDocument = {
    _id: ObjectId;
    codigo: number;
    nome: string;
    descricao: string;
    orientacoes: string[];
    duracaoPadraoMinutos: number;
    materiais: ExerciseMaterial[];
    privacidade: ExercisePrivacy;
    // Presente apenas quando privacidade = ESPECIFICO.
    cavalo?: ExerciseHorseRef;
    // Exclusão lógica.
    ativo: boolean;
    // Caminhos no Storage (formato do DD), na ordem de envio.
    imagens: string[];
    videos: string[];
    cadastrante: ExerciseRegistrant;
    // Omitido quando cadastrante = PLATAFORMA.
    treinador?: ExerciseTrainerRef;
    criadoEm: Date;
    atualizadoEm: Date;
};

// Dados enviados ao repository; o 'codigo' é gerado na própria inserção.
export type NewExercise = Omit<ExerciseDocument, "codigo">;

// Campos informados no cadastro e alteráveis na edição.
export type ExerciseDetailsInput = {
    nome: string;
    descricao: string;
    orientacoes: string[];
    duracaoPadraoMinutos: number;
    materiais: ExerciseMaterial[];
};

// cavaloId é null quando privacidade = GENERICO; a validação recusa
// combinações incoerentes.
export type ExerciseRegistrationInput = ExerciseDetailsInput & {
    privacidade: ExercisePrivacy;
    cavaloId: ObjectId | null;
};

export type ExerciseRegistrationResult = {
    id: string;
    codigo: number;
    nome: string;
};

export type ExerciseImageContentType = "image/jpeg" | "image/png";

export type ExerciseVideoContentType = "video/mp4";

export type ExerciseMediaContentType =
    | ExerciseImageContentType
    | ExerciseVideoContentType;

// Campo do documento que guarda os caminhos de cada tipo de mídia.
export type ExerciseMediaField = "imagens" | "videos";

// O formato define se o arquivo vai para 'imagens' ou para 'videos'.
export type ExerciseMediaUploadInput = {
    id: ObjectId;
    contentType: ExerciseMediaContentType;
};

// Usado para confirmar o envio e para remover uma mídia.
export type ExerciseMediaFileInput = {
    id: ObjectId;
    caminho: string;
};

export type ExerciseMediaUploadResult = {
    caminho: string;
    uploadUrl: string;
    headers: Record<string, string>;
};

// Formato enviado ao app: caminho (formato do DD) e URL assinada de leitura.
export type ExerciseMediaView = {
    caminho: string;
    url: string;
};

// Filtro da galeria. Sem cavaloId, lista os genéricos do treinador; com ele,
// os específicos daquele cavalo.
export type ExerciseGalleryInput = {
    busca?: string;
    cavaloId: ObjectId | null;
};

// Campos de 'exercicios' lidos pela galeria.
export type ExerciseGallerySource = Pick<
    ExerciseDocument,
    "_id" | "nome" | "duracaoPadraoMinutos" | "privacidade" | "cavalo"
>;

// Tipo e cavalo do exercício, lidos pelos detalhes do treinamento.
export type ExerciseKindSource = Pick<
    ExerciseDocument,
    "_id" | "privacidade" | "cavalo"
>;

// Item da galeria; 'cavalo' só no exercício específico.
export type ExerciseGalleryItem = {
    id: string;
    nome: string;
    duracaoPadraoMinutos: number;
    privacidade: ExercisePrivacy;
    cavalo?: {id: string; codigo: string; nome: string};
};

export type ExerciseGalleryResult = {exercicios: ExerciseGalleryItem[]};

// Soma de duracaoPadraoMinutos dos exercícios selecionados.
export type ExerciseDurationSumResult = {duracaoTotalMinutos: number};

// Consulta de um exercício: pelo _id ou pelo código, nunca pelos dois.
export type ExerciseLookup = {id: ObjectId} | {codigo: number};

// Cavalo do exercício na consulta e na edição; 'codigo' é o microchip.
export type ExerciseHorseView = {id: string; codigo: string; nome: string};

// O que quem consulta pode fazer com o exercício.
export type ExercisePermissions = {editar: boolean};

// Resposta de getExercise e de updateExercise: _id viram 'id' (string) e
// datas viram ISO.
export type ExerciseView = {
    id: string;
    codigo: number;
    nome: string;
    descricao: string;
    orientacoes: string[];
    duracaoPadraoMinutos: number;
    materiais: ExerciseMaterial[];
    privacidade: ExercisePrivacy;
    // Só no ESPECIFICO, e só para o autor ou para quem tem vínculo com o
    // cavalo: um exercício que mudou de cavalo depois de planejado não
    // revela o cavalo novo a quem só conhece o antigo.
    cavalo?: ExerciseHorseView;
    treinador: RefView;
    imagens: ExerciseMediaView[];
    videos: ExerciseMediaView[];
    permissoes: ExercisePermissions;
    criadoEm: string;
    atualizadoEm: string;
};

// Edição: só os campos enviados mudam. 'cavaloId' só vem junto com
// 'privacidade' e é null no GENERICO.
export type ExerciseUpdateChanges = Partial<ExerciseDetailsInput> & {
    privacidade?: ExercisePrivacy;
    cavaloId?: ObjectId | null;
};

export type ExerciseUpdateInput = {
    id: ObjectId;
    changes: ExerciseUpdateChanges;
};

// Relação de quem consulta com o exercício; sem acesso, a regra devolve
// null.
export type ExerciseAccess = {isAuthor: boolean; showHorse: boolean};

// Exercício cadastrado por um treinador. Os da plataforma não têm autor e
// nunca chegam à consulta nem à edição.
export type AuthoredExercise = ExerciseDocument & {
    treinador: ExerciseTrainerRef;
};
