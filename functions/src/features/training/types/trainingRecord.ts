// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos das consultas de registros de treino.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";

export type TrainingRecordStatus =
    | "PLANEJADO"
    | "REALIZADO"
    | "PARCIAL"
    | "NAO_REALIZADO"
    | "CANCELADO";

// Projeção usada na listagem do dia. CANCELADO é excluído na consulta.
export type DayTrainingRecord = {
    _id: ObjectId;
    status: Exclude<TrainingRecordStatus, "CANCELADO">;
    plano?: {titulo: string};
    cavalo?: {nome: string};
    treinador?: {nome: string};
    treinamento?: {titulo: string; duracaoEstimadaMinutos: number};
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
