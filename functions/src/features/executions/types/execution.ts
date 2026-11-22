// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Tipos da visualização do treino agendado, da execução, do
// feedback e da lista de execuções que esperam feedback.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import type {ExerciseMaterial, ExerciseMediaView} from "../../exercises";
import type {
  ExerciseCompletion,
  ReportedRecordStatus,
  TrainingRecordStatus,
} from "../../training";

// Marcação de um exercício no envio: PENDENTE não é aceito.
export type MarkedCompletion = Exclude<ExerciseCompletion, "PENDENTE">;

// Tipo de conta de quem consulta, como em getTrainingPlanDetails.
export type RecordViewerRole = "TREINADOR" | "RESPONSAVEL";

export type TrainingRecordInput = {registroId: ObjectId};

// Uma marcação por posição do treino, na ordem. 'codigo' é o do exercício
// naquela posição, conferido com a cópia atual do treino.
export type ExecutionMark = {
    codigo: number;
    realizacao: MarkedCompletion;
    observacao?: string;
};

// 'status' é deduzido na validação; duração, percepção e dificuldades só
// existem quando algum exercício foi realizado.
export type ExecutionInput = {
    registroId: ObjectId;
    exercicios: ExecutionMark[];
    status: ReportedRecordStatus;
    duracaoEfetiva?: number;
    percepcaoDesempenho?: number;
    dificuldades?: string;
    observacoes: string[];
};

export type FeedbackInput = {
    registroId: ObjectId;
    comentario: string;
    dificuldadesIdentificadas: string[];
    orientacoes: string[];
};

// Relação de quem pede com o treino, resolvida pelo servidor.
export type RecordViewer = {
    role: RecordViewerRole;
    // Treinador do plano que gerou o treino.
    isPlanTrainer: boolean;
    // Atleta do cavalo hoje, com o cavalo ativo.
    isAthlete: boolean;
};

export type RecordPermissions = {
    podeRegistrarExecucao: boolean;
    podeRegistrarFeedback: boolean;
};

export type RecordExerciseView = {
    posicao: number;
    codigo: string;
    nome: string;
    descricao: string;
    orientacoes: string[];
    // Minutos (duracaoPadraoMinutos da cópia).
    duracao: number;
    realizacao: ExerciseCompletion;
    observacao: string | null;
    materiais: ExerciseMaterial[];
    midias: {
        imagens: ExerciseMediaView[];
        videos: ExerciseMediaView[];
        // Sem nenhuma foto nem vídeo: o app mostra o aviso.
        semMidias: boolean;
    };
};

export type ExecutionView = {
    // null em registro REALIZADO ou PARCIAL antigo, gravado sem a data.
    dataExecucao: string | null;
    duracaoEfetiva: number | null;
    percepcaoDesempenho: number | null;
    dificuldades: string;
    observacoes: string[];
    exerciciosRealizados: number;
    exerciciosNaoRealizados: number;
};

export type FeedbackView = {
    data: string;
    comentario: string;
    dificuldadesIdentificadas: string[];
    orientacoes: string[];
};

export type TrainingRecordView = {
    role: RecordViewerRole;
    registro: {
        id: string;
        codigo: number;
        status: TrainingRecordStatus;
        dataPlanejada: string;
    };
    plano: {id: string; titulo: string; objetivo: string};
    treinamento: {
        codigo: string;
        titulo: string;
        descricao: string;
        orientacoes: string[];
        duracaoEstimada: number;
    };
    cavalo: {id: string; nome: string};
    treinador: {nome: string};
    atleta: {nome: string} | null;
    exercicios: RecordExerciseView[];
    execucao: ExecutionView | null;
    feedback: FeedbackView | null;
    permissoes: RecordPermissions;
};

export type PendingFeedbackItem = {
    id: string;
    // null em registro antigo sem 'dataExecucao' (vem por último).
    data: string | null;
    status: ReportedRecordStatus;
    duracaoEfetiva: number | null;
    nomeTreinamento: string;
    nomeCavalo: string;
    nomeAtleta: string | null;
};

export type PendingFeedbackList = {
    execucoes: PendingFeedbackItem[];
    possuiMais: boolean;
};
