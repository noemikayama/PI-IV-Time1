// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cópia do treinamento guardada no item do planejamento do plano.
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos do documento e do cadastro de treinamentos.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";

// Exercício em uso (DD 3.5): cópia dos dados do exercício no momento da
// inclusão. '_id' e 'codigo' são os do exercício de origem.
export type TrainingExercise = {
    _id: ObjectId;
    codigo: number;
    nome: string;
    descricao: string;
    orientacoes: string[];
    duracaoPadraoMinutos: number;
};

// Referência resumida ao treinador dentro de treinamentos.treinador.
export type TrainingTrainerRef = {_id: string; codigo: number; nome: string};

// Coleção 'treinamentos'.
export type TrainingDocument = {
    _id: ObjectId;
    codigo: number;
    titulo: string;
    // Omitida quando não informada.
    descricao?: string;
    orientacoes: string[];
    duracaoEstimadaMinutos: number;
    treinador: TrainingTrainerRef;
    // A ordem da lista é a ordem de execução.
    exercicios: TrainingExercise[];
    criadoEm: Date;
    atualizadoEm: Date;
};

// Cópia do treinamento no item do planejamento (DD 3.6), com os exercícios
// em uso. '_id' e 'codigo' são os do treinamento de origem.
export type TrainingSnapshot = Omit<
    TrainingDocument,
    "treinador" | "criadoEm" | "atualizadoEm"
>;

// Dados enviados ao repository; o 'codigo' é gerado na própria inserção.
export type NewTraining = Omit<TrainingDocument, "codigo">;

// 'exercicios' chega como a lista de _id, na ordem de execução.
export type TrainingRegistrationInput = {
    titulo: string;
    descricao?: string;
    orientacoes: string[];
    duracaoEstimadaMinutos: number;
    exercicios: ObjectId[];
};

// Formato enviado ao app: _id viram 'id' (string) e datas viram ISO.
export type TrainingExerciseView = Omit<TrainingExercise, "_id"> & {
    id: string;
};

export type TrainingView = Omit<
    TrainingDocument,
    "_id" | "treinador" | "exercicios" | "criadoEm" | "atualizadoEm"
> & {
    id: string;
    treinador: {id: string; codigo: number; nome: string};
    exercicios: TrainingExerciseView[];
    criadoEm: string;
    atualizadoEm: string;
};
