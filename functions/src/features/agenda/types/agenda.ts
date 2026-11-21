// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos da entrada e da resposta da agenda de treinos.
// Alteração: Treinos de hoje e histórico de execuções separados dos
// treinamentos da semana; status no treinamento.
// Alteração: Cargo do usuário em cada treino de hoje (define o botão) no
// lugar da ação nos treinamentos da semana.
// -----------------------------------------------------------------------------

import type {TrainingRecordStatus} from "../../training";

// Dia usado para escolher a semana (meia-noite UTC).
export type AgendaFiltro = {data: Date};

// Cargo do usuário no treino. Atleta e proprietário do mesmo cavalo é
// ATLETA, que é quem inicia o treino.
export type AgendaCargo = "TREINADOR" | "ATLETA" | "PROPRIETARIO";

// Status mostrado ao usuário: PLANEJADO de dia passado sai como
// NAO_REALIZADO. CANCELADO não aparece na agenda.
export type AgendaStatus = Exclude<TrainingRecordStatus, "CANCELADO">;

// Datas em AAAA-MM-DD; _id como string hexadecimal ('id').
export type AgendaPlano = {
    id: string;
    titulo: string;
    nomeCavalo: string;
    // Só para o responsável.
    nomeTreinador?: string;
    dataInicio: string;
    dataFim: string;
};

export type AgendaDia = {data: string; quantidadeTreinos: number};

// Treinamento da semana (lista do dia selecionado no calendário). O botão
// "Ver detalhes" é o mesmo para todos e fica a cargo do front.
export type AgendaTreinamento = {
    id: string;
    nomeTreinamento: string;
    nomeCavalo: string;
    nomePlano: string;
    data: string;
    status: AgendaStatus;
};

// Treino de hoje (carrossel "Treinos do dia").
export type AgendaTreinoDoDia = {
    id: string;
    nomeTreinamento: string;
    nomeCavalo: string;
    // Só para o responsável.
    nomeTreinador?: string;
    duracaoEstimadaMinutos: number;
    nomePlano: string;
    // ATLETA: "Iniciar treino"; TREINADOR e PROPRIETARIO: "Ver treino".
    role: AgendaCargo;
};

// Execução do histórico; 'data' é a data de execução.
export type AgendaExecucao = {
    id: string;
    nomeTreinamento: string;
    nomeCavalo: string;
    data: string;
    status: "REALIZADO" | "PARCIAL";
};

export type AgendaResult = {
    role: "TREINADOR" | "RESPONSAVEL";
    // Hoje no fuso de São Paulo: o dia selecionado ao abrir a tela.
    hoje: string;
    // Segunda e domingo da semana.
    semana: {dataInicio: string; dataFim: string};
    planosAtivos: {quantidade: number; planos: AgendaPlano[]};
    // Sete itens, de segunda a domingo, inclusive os dias sem treino.
    dias: AgendaDia[];
    // Treinamentos da semana, em ordem de data.
    treinamentos: AgendaTreinamento[];
    // Sempre os de hoje, seja qual for a semana pedida.
    treinosDoDia: {total: number; treinos: AgendaTreinoDoDia[]};
    // Execuções mais recentes primeiro, com limite.
    historicoExecucoes: AgendaExecucao[];
};
