// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Projeção do plano ativo usada pela agenda.
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos do documento e do cadastro de planos de treinamento, do
// seletor de avaliações e da galeria de treinamentos.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import type {EvaluationDocument} from "../../evaluations";
import type {TrainingSnapshot} from "../../training";

export const DIAS_SEMANA = [
  "SEGUNDA",
  "TERCA",
  "QUARTA",
  "QUINTA",
  "SEXTA",
  "SABADO",
  "DOMINGO",
] as const;

export type DiaSemana = typeof DIAS_SEMANA[number];

export type PlanStatus = "RASCUNHO" | "ATIVO" | "CONCLUIDO" | "CANCELADO";

// Item do planejamento (DD 3.6, alterado): um item por treinamento, com os
// dias da semana em que ele ocorre, em vez de uma data. O código é único no
// plano e nunca é reaproveitado; uma edição desativa o item e cria outro.
export type PlanningItem = {
    codigo: number;
    ativo: boolean;
    // De SEGUNDA a DOMINGO; um dia aparece em no máximo um item.
    diasSemana: DiaSemana[];
    treinamento: TrainingSnapshot;
};

// Cópia da avaliação que originou o plano (DD 2.7), com o _id da original.
export type PlanEvaluationCopy = Omit<
    EvaluationDocument,
    "cavalo" | "treinador" | "criadoEm" | "atualizadoEm"
>;

// Coleção 'planos'.
export type PlanDocument = {
    _id: ObjectId;
    codigo: number;
    titulo: string;
    objetivo: string;
    cavalo: {_id: ObjectId; codigo: string; nome: string};
    treinador: {_id: string; codigo: number; nome: string};
    // Omitida enquanto a avaliação for opcional.
    avaliacaoInicial?: PlanEvaluationCopy;
    status: PlanStatus;
    // Datas de calendário à meia-noite UTC.
    dataInicio: Date;
    dataFim: Date;
    planejamento: PlanningItem[];
    criadoEm: Date;
    atualizadoEm: Date;
};

// Projeção do plano ativo listado na agenda.
export type ActivePlanSummary = Pick<
    PlanDocument,
    "_id" | "titulo" | "dataInicio" | "dataFim"
> & {
    cavalo: Pick<PlanDocument["cavalo"], "nome">;
    treinador: Pick<PlanDocument["treinador"], "nome">;
};

// Treino escolhido em cada dia; null deixa o dia vazio.
export type TrainingsByDay = Record<DiaSemana, ObjectId | null>;

export type TrainingPlanInput = {
    titulo: string;
    objetivo: string;
    cavaloId: ObjectId;
    avaliacaoId: ObjectId | null;
    // AAAA-MM-DD.
    dataInicio: string;
    dataFim: string;
    treinosPorDia: TrainingsByDay;
};

// Formato enviado ao app: _id viram 'id' (string).
export type PlanningItemView = {
    codigo: number;
    diasSemana: DiaSemana[];
    treinamento: Omit<TrainingSnapshot, "_id" | "exercicios"> & {
        id: string;
        exercicios: (Omit<TrainingSnapshot["exercicios"][number], "_id"> & {
            id: string;
        })[];
    };
};

export type TrainingPlanResult = {
    plano: {
        id: string;
        codigo: number;
        status: PlanStatus;
        dataInicio: string;
        dataFim: string;
        planejamento: PlanningItemView[];
    };
    registrosGerados: number;
};

// Seletor da avaliação base: mais recente primeiro.
export type HorseEvaluationsResult = {
    avaliacoes: {id: string; codigo: number; data: string}[];
};

export type TrainingGalleryInput = {cavaloId: ObjectId; busca?: string};

// Card da galeria: nomes dos exercícios na ordem de execução.
export type TrainingGalleryItem = {
    id: string;
    codigo: number;
    titulo: string;
    duracaoEstimadaMinutos: number;
    exercicios: string[];
};

export type TrainingGalleryResult = {treinamentos: TrainingGalleryItem[]};
