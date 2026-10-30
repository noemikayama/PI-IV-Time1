// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Filtro do painel profissional, janela com instantes e as duas
// respostas do dashboard do treinador.
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos dos filtros e da resposta do dashboard do responsável.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import type {DatePeriod} from "../../../shared/utils/dates";

// Períodos aceitos pelo filtro. Todos terminam no fim do dia de hoje; SEMPRE
// só não tem início (ver dashboardPeriod.ts).
export type DashboardPeriodo =
    | "SEMPRE"
    | "DIARIO"
    | "SEMANAL"
    | "MENSAL"
    | "SEMESTRAL"
    | "ANUAL";

// Filtros com formato já validado. 'cavaloId' nulo significa todos os
// cavalos. As regras de 'painelProfissional' por perfil (exclusivo do
// treinador, sem 'cavaloId') ficam nos services.
export type DashboardFiltros = {
    periodo: DashboardPeriodo;
    cavaloId: ObjectId | null;
    painelProfissional: boolean;
};

// Janela do período. 'range' filtra datas de calendário (dataPlanejada,
// dataExecucao, avaliacoes.data) e 'instants' filtra campos com hora
// (criadoEm, feedback.data), no fuso de São Paulo. Sempre terminam no fim
// de hoje, inclusive em SEMPRE, que só não tem início ('inicio' nulo).
export type DashboardWindow = {
    range: DatePeriod;
    instants: DatePeriod;
    inicio: string | null;
    fim: string;
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

// Campos comuns às duas visões do treinador.
interface DashboardTreinadorBase {
    tipoConta: "TREINADOR";
    periodo: DashboardPeriodo;
    inicio: string | null;
    fim: string;
}

// Painel profissional desativado: evolução dos cavalos vinculados.
export interface DashboardTreinadorCavalos extends DashboardTreinadorBase {
    painelProfissional: false;
    cavaloId: string | null;
    cavalos: RefCavalo[];
    // false sem cavalos ou sem treinos no período: "Sem dados para exibir".
    possuiDados: boolean;
    treinosRealizados: TreinosRealizados;
    cumprimentoTreinos: CumprimentoTreinos;
    frequenciaExecucao: FrequenciaExecucao;
    ultimosTreinos: TreinoRecente[];
    // true quando há mais treinos na janela do que os listados
    // ("Mostrar tudo").
    possuiMaisTreinos: boolean;
}

// Gráfico de setores "Planos criados". O status é o atual de cada plano e
// os quatro percentuais somam 100 quando há planos.
export interface PlanosCriados {
    total: number;
    ativos: number;
    concluidos: number;
    cancelados: number;
    rascunhos: number;
    percentualAtivos: number;
    percentualConcluidos: number;
    percentualCancelados: number;
    percentualRascunhos: number;
}

// Card "Percentual de feedbacks dados": registros executados dos planos do
// treinador que já têm feedback.
export interface FeedbacksDados {
    percentual: number;
    comFeedback: number;
    executados: number;
}

// Painel profissional ativado: produção do próprio treinador. Não tem
// 'possuiDados': sem produção, a tela mostra os cards zerados.
export interface DashboardTreinadorProfissional
    extends DashboardTreinadorBase {
    painelProfissional: true;
    planosCriados: PlanosCriados;
    feedbacksDados: FeedbacksDados;
    // Vínculos atuais: o modelo não guarda a data do vínculo.
    clientesVinculados: number;
    cavalosVinculados: number;
    avaliacoesFeitas: number;
    exerciciosCriados: number;
}

export type DashboardTreinador =
    | DashboardTreinadorCavalos
    | DashboardTreinadorProfissional;

export type DashboardResult = DashboardResponsavel | DashboardTreinador;

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

// Contagem de planos por status atual, sobre a coleção 'planos'.
export type PlanosStatusRow = {
    ativos: number;
    concluidos: number;
    cancelados: number;
    rascunhos: number;
};

export type DashboardAgregado = {
    indicadores: DashboardIndicadoresRow;
    ultimosTreinos: TreinoRecenteRow[];
    ultimosFeedbacks: FeedbackRecenteRow[];
};
