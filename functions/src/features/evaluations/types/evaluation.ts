// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos da criação e da consulta de avaliações do cavalo.
// Alteração: Cards do histórico movidos para o perfil do cavalo.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import type {HorseDocument, RefView} from "../../horses";

type ModalityRef = {_id: ObjectId; codigo: number; nome: string};

// Coleção 'avaliacoes' (DD 2.4). Não é editada depois de criada (RF06005).
export type EvaluationDocument = {
    _id: ObjectId;
    codigo: number;
    cavalo: {_id: ObjectId; codigo: string; nome: string};
    treinador: {_id: string; codigo: number; nome: string};
    // Data em que o cavalo foi avaliado (AAAA-MM-DD).
    data: string;
    condicionamentoFisicoObservado: string;
    // Textos livres opcionais, omitidos quando não informados.
    limitacoes?: string;
    dificuldades?: string;
    // Podem diferir da modalidade principal do cavalo.
    modalidades: ModalityRef[];
    observacoes: string[];
    criadoEm: Date;
    atualizadoEm: Date;
};

// Dados enviados ao repository; o 'codigo' é gerado na própria inserção.
export type NewEvaluation = Omit<EvaluationDocument, "codigo">;

// Item de cavalos.avaliacoes (histórico resumido do cavalo).
export type EvaluationSummary = HorseDocument["avaliacoes"][number];

export type EvaluationCreateInput = {
    cavaloId: ObjectId;
    data: string;
    condicionamentoFisicoObservado: string;
    limitacoes?: string;
    dificuldades?: string;
    // Sem repetição, na ordem informada.
    modalidadeIds: ObjectId[];
    observacoes: string[];
};

// Avaliação criada, no formato do app.
export type EvaluationView = {
    id: string;
    codigo: number;
    cavalo: {id: string; codigo: string; nome: string};
    treinador: RefView;
    data: string;
    condicionamentoFisicoObservado: string;
    limitacoes: string | null;
    dificuldades: string | null;
    modalidades: RefView[];
    observacoes: string[];
    criadoEm: string;
};
