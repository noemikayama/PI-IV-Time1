// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 07/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos do documento, do cadastro e das mídias de exercícios.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";

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

// Campos informados no cadastro e, futuramente, alteráveis na edição.
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
