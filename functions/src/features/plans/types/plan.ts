// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos da tela de visualização e do cancelamento do plano.
// Alteração: Entrada da edição do plano e treinos por dia na
// visualização; o item do planejamento é mantido por treinamento.
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
// plano e nunca é reaproveitado. Na edição, o treinamento que continua no
// plano mantém o item (só os dias mudam); o que sai tem o item desativado.
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

// Campos substituídos pela edição; 'avaliacaoInicial' ausente é removida.
export type PlanContent = Pick<
    PlanDocument,
    | "titulo"
    | "objetivo"
    | "cavalo"
    | "avaliacaoInicial"
    | "dataInicio"
    | "dataFim"
    | "planejamento"
    | "atualizadoEm"
>;

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

// Treino de um dia na visualização, para a tela de edição vir preenchida.
export type PlanDayTrainingView = {
    id: string;
    codigo: number;
    titulo: string;
    duracaoEstimadaMinutos: number;
};

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

// Pedido da visualização e do cancelamento do plano.
export type PlanIdInput = {planoId: ObjectId};

// Edição: o estado final da tela, com os campos do cadastro.
export type TrainingPlanUpdateInput = TrainingPlanInput & PlanIdInput;

// Perfil de quem consulta, lido da conta (papel do token conferido no banco).
export type PlanViewerRole = "TREINADOR" | "RESPONSAVEL";

// Uma data prevista do plano com a cópia do treinamento do item. Datas em
// AAAA-MM-DD; 'dataPorExtenso' e 'diaSemana' já vêm em português.
export type PlanSessionView = {
    data: string;
    // "Segunda-feira, 23 de novembro de 2026".
    dataPorExtenso: string;
    // "Segunda-feira".
    diaSemana: string;
    treinamento: {
        // String, como a getTrainingDetails recebe ("Ver detalhes").
        codigo: string;
        titulo: string;
        duracaoEstimadaMinutos: number;
        // "" quando o treinamento não tem descrição.
        descricao: string;
        // Nomes dos exercícios, na ordem de execução.
        exercicios: string[];
    };
};

export type PlanSessionList = {total: number; treinos: PlanSessionView[]};

export type TrainingPlanDetailsResult = {
    role: PlanViewerRole;
    plano: {
        id: string;
        codigo: number;
        titulo: string;
        objetivo: string;
        dataInicio: string;
        dataFim: string;
        // Um ATIVO vencido (dataFim antes de hoje) aparece como CONCLUIDO.
        status: PlanStatus;
    };
    cavalo: {id: string; nome: string};
    // Autor do plano; só para quem não é o autor.
    nomeTreinador?: string;
    // Sempre false para o responsável.
    permissoes: {podeEditar: boolean; podeCancelar: boolean};
    // Avaliação que originou o plano, ou null.
    avaliacao: {
        id: string;
        codigo: number;
        data: string;
        nomeCavalo: string;
    } | null;
    // Semana atual (segunda a domingo, fuso de São Paulo). Vazia enquanto o
    // plano não começou.
    treinosDaSemana: PlanSessionList & {dataInicio: string; dataFim: string};
    // "Ver tudo": todas as datas do plano, em ordem crescente.
    todosOsTreinos: PlanSessionList;
    // Treino de cada dia (null = sem treino), como 'treinosPorDia' do
    // cadastro e da edição.
    treinosPorDia: Record<DiaSemana, PlanDayTrainingView | null>;
};
