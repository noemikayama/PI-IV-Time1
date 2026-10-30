// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos dos filtros e da resposta do dashboard do responsável.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";

// Períodos aceitos pelo filtro. SEMPRE não limita a data; os demais são
// janelas que terminam no fim do dia de hoje (ver dashboardPeriod.ts).
export type DashboardPeriodo =
    | "SEMPRE"
    | "DIARIO"
    | "SEMANAL"
    | "MENSAL"
    | "SEMESTRAL"
    | "ANUAL";

// Filtros já validados. 'cavaloId' nulo significa todos os cavalos.
export type DashboardFiltros = {
    periodo: DashboardPeriodo;
    cavaloId: ObjectId | null;
};

// Referência resumida usada no seletor de cavalos do filtro.
export interface RefCavalo {
    id: string;
    nome: string;
}

// Gráfico de setores "Treinos realizados". 'total' é o número do centro do
// gráfico: REALIZADO + PARCIAL.
export interface TreinosRealizados {
    realizados: number;
    parciais: number;
    total: number;
    percentualRealizados: number;
    percentualParciais: number;
}

// Card "Percentual de cumprimento dos treinos". A média é feita apenas
// sobre os treinos executados que têm duração estimada e efetiva.
export interface CumprimentoTreinos {
    percentual: number;
    treinosConsiderados: number;
}

// Card "Frequência de execução dos treinos": executados sobre previstos.
export interface FrequenciaExecucao {
    percentual: number;
    executados: number;
    previstos: number;
}

// Card da lista "Últimos treinos". 'data' é a data de execução.
export interface TreinoRecente {
    registroId: string;
    nomeTreino: string;
    nomeCavalo: string;
    nomePlano: string;
    data: string;
}

// Card da lista "Últimos feedbacks". 'data' é o momento do feedback.
export interface FeedbackRecente {
    registroId: string;
    nomeTreino: string;
    nomePlano: string;
    data: string;
}

export interface DashboardResponsavel {
    tipoConta: "RESPONSAVEL";
    periodo: DashboardPeriodo;
    // Limites aplicados, em AAAA-MM-DD. 'inicio' é nulo quando SEMPRE.
    inicio: string | null;
    fim: string;
    // Filtro aplicado e lista completa para o seletor "Todos".
    cavaloId: string | null;
    cavalos: RefCavalo[];
    // false quando não há nada no período: o app mostra "Sem dados".
    possuiDados: boolean;
    treinosRealizados: TreinosRealizados;
    cumprimentoTreinos: CumprimentoTreinos;
    frequenciaExecucao: FrequenciaExecucao;
    ultimosTreinos: TreinoRecente[];
    ultimosFeedbacks: FeedbackRecente[];
}

// A resposta do treinador entra nesta união quando for implementada.
export type DashboardResult = DashboardResponsavel;

// ---------------------------------------------------------------------------
// Resultado bruto da agregação sobre 'registros_treino'.
// ---------------------------------------------------------------------------

// Contagens do período. 'somaCumprimento' é a soma das razões entre duração
// efetiva e estimada (cada uma limitada a 1) dos treinos considerados.
export type DashboardIndicadoresRow = {
    previstos: number;
    realizados: number;
    parciais: number;
    somaCumprimento: number;
    treinosConsiderados: number;
};

export type TreinoRecenteRow = {
    _id: ObjectId;
    dataExecucao: Date;
    treinamento?: {titulo?: string};
    cavalo?: {nome?: string};
    plano?: {titulo?: string};
};

export type FeedbackRecenteRow = {
    _id: ObjectId;
    feedback: {data: Date};
    treinamento?: {titulo?: string};
    plano?: {titulo?: string};
};

export type DashboardAgregado = {
    indicadores: DashboardIndicadoresRow;
    ultimosTreinos: TreinoRecenteRow[];
    ultimosFeedbacks: FeedbackRecenteRow[];
};
