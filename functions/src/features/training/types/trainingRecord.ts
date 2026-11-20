// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Projeção das listagens por período (home e agenda), com a
// data prevista, a de execução e o _id do cavalo.
// Alteração: Projeção das execuções recentes (histórico da agenda).
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Documento do registro de treino, gerado na ativação do plano.
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Nome do atleta (responsavel) na projeção do dia.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos das consultas de registros de treino.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import type {TrainingExercise, TrainingSnapshot} from "./training";

export type TrainingRecordStatus =
    | "PLANEJADO"
    | "REALIZADO"
    | "PARCIAL"
    | "NAO_REALIZADO"
    | "CANCELADO";

// Referência resumida a uma conta (responsável ou treinador).
type AccountRef = {_id: string; codigo: number; nome: string};

// Cópia do treinamento (DD 3.7): a do item do planejamento, sem os
// exercícios, que ficam em 'exercicios'.
export type TrainingRecordTraining = Omit<TrainingSnapshot, "exercicios">;

export type ExerciseCompletion = "PENDENTE" | "REALIZADO" | "NAO_REALIZADO";

// Exercício Realizado (DD 3.9). Nasce PENDENTE; 'video' e
// 'observacoesEspecificas' são informados pelo atleta na execução e ficam
// omitidos até lá.
export type PerformedExercise = {
    exercicio: TrainingExercise;
    realizacao: ExerciseCompletion;
    video?: string;
    observacoesEspecificas?: string;
};

// Feedback do treinador (DD 3.8), embutido no registro.
export type TrainingFeedback = {
    data: Date;
    comentario: string;
    dificuldadesIdentificadas: string[];
    orientacoes: string[];
};

// Coleção 'registros_treino' (DD 2.8): uma sessão por registro, gerada na
// ativação do plano.
export type TrainingRecordDocument = {
    _id: ObjectId;
    codigo: number;
    plano: {_id: ObjectId; codigo: number; titulo: string};
    // Código do item do planejamento que originou o registro.
    itemPlanejamento: number;
    // Atleta do cavalo na geração, omitido se não houver. A agenda é lida
    // por cavalo, então a troca de atleta não esconde nenhum registro.
    responsavel?: AccountRef;
    cavalo: {_id: ObjectId; codigo: string; nome: string};
    treinador: AccountRef;
    // Semana do plano: 1 são os 7 primeiros dias a partir de dataInicio.
    semana: number;
    status: TrainingRecordStatus;
    // Datas de calendário à meia-noite UTC.
    dataPlanejada: Date;
    // Campos da execução e do feedback: ausentes até o registro.
    dataExecucao?: Date;
    duracaoEfetivaMinutos?: number;
    percepcaoDesempenho?: string;
    dificuldade?: string;
    observacoes?: string[];
    treinamento: TrainingRecordTraining;
    exercicios: PerformedExercise[];
    feedback?: TrainingFeedback;
    criadoEm: Date;
    atualizadoEm: Date;
};

// Registro montado pelo plano; o 'codigo' é reservado na inserção.
export type NewTrainingRecord = Omit<TrainingRecordDocument, "codigo">;

// Projeção das listagens por período (o dia na home, a semana na agenda).
// CANCELADO é excluído na consulta.
export type TrainingRecordSummary = {
    _id: ObjectId;
    status: Exclude<TrainingRecordStatus, "CANCELADO">;
    dataPlanejada: Date;
    dataExecucao?: Date;
    plano?: {titulo: string};
    // O atleta do cavalo é gravado no registro como responsável.
    responsavel?: {nome: string};
    cavalo?: {_id: ObjectId; nome: string};
    treinador?: {nome: string};
    treinamento?: {titulo: string; duracaoEstimadaMinutos: number};
};

// Projeção das execuções recentes (histórico da agenda).
export type RecentExecutionRecord = {
    _id: ObjectId;
    status: "REALIZADO" | "PARCIAL";
    dataExecucao?: Date;
    cavalo?: {nome: string};
    treinamento?: {titulo: string};
};

// executed são REALIZADO + PARCIAL; total são os registros do período
// sem CANCELADO.
export type ExecutionCount = {executed: number; total: number};

export type HorseExecutionCounts = {
    week: ExecutionCount;
    month: ExecutionCount;
    allTimeExecuted: number;
};

// Das sessões executadas no período, quantas já têm feedback.
export type FeedbackCount = {withFeedback: number; executed: number};
