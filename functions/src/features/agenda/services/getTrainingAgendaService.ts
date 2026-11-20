// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Agenda de treinos do treinador e do responsável.
// Alteração: Treinos de hoje (reaproveitando a semana quando ela contém
// hoje), histórico das execuções mais recentes e status no treinamento.
// Alteração: Cargo do usuário em cada treino de hoje no lugar da ação nos
// treinamentos da semana.
// -----------------------------------------------------------------------------

import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {
  addDays,
  getDayStart,
  getWeekOf,
  toYmd,
} from "../../../shared/utils/dates";
import type {DatePeriod} from "../../../shared/utils/dates";
import {findGuardianHomeSource} from "../../authentication/guardian";
import {assertActiveAccount} from "../../horses";
import {findActivePlansByHorses, findActivePlansByTrainer} from "../../plans";
import type {ActivePlanSummary} from "../../plans";
import {
  findRecentExecutionsByHorses,
  findRecentExecutionsByTrainer,
  findRecordsByHorses,
  findRecordsByTrainer,
} from "../../training";
import type {
  RecentExecutionRecord,
  TrainingRecordSummary,
} from "../../training";
import type {
  AgendaCargo,
  AgendaDia,
  AgendaExecucao,
  AgendaFiltro,
  AgendaPlano,
  AgendaResult,
  AgendaStatus,
  AgendaTreinamento,
  AgendaTreinoDoDia,
} from "../types";

// Tamanho do histórico de execuções.
export const AGENDA_HISTORY_LIMIT = 10;

// O que muda entre os perfis na montagem da resposta.
type AgendaViewer = {
    role: AgendaResult["role"];
    // O nome do treinador só é mostrado ao responsável.
    showTrainer: boolean;
    roleOf: (record: TrainingRecordSummary) => AgendaCargo;
};

// Consultas por perfil: pelos cavalos (responsável) ou pelo treinador.
type AgendaSources = {
    plans: (today: Date) => Promise<ActivePlanSummary[]>;
    records: (period: DatePeriod) => Promise<TrainingRecordSummary[]>;
    history: (limit: number) => Promise<RecentExecutionRecord[]>;
};

// Dados lidos do banco para montar a resposta.
type AgendaData = {
    plans: ActivePlanSummary[];
    weekRecords: TrainingRecordSummary[];
    todayRecords: TrainingRecordSummary[];
    executions: RecentExecutionRecord[];
};

const EMPTY_DATA: AgendaData = {
  plans: [],
  weekRecords: [],
  todayRecords: [],
  executions: [],
};

/** Status mostrado: um PLANEJADO de dia passado não foi feito. Um plano
 * vencido só é concluído quando outro é criado, então o banco pode ainda
 * ter PLANEJADO no passado.
 * @param {TrainingRecordSummary} record Registro de treino.
 * @param {Date} today Hoje (meia-noite UTC).
 * @return {AgendaStatus} Status da agenda.
 */
const statusOf = (
  record: TrainingRecordSummary,
  today: Date
): AgendaStatus =>
  record.status === "PLANEJADO" && record.dataPlanejada < today ?
    "NAO_REALIZADO" :
    record.status;

const toPlano = (
  plan: ActivePlanSummary,
  viewer: AgendaViewer
): AgendaPlano => ({
  id: plan._id.toHexString(),
  titulo: plan.titulo,
  nomeCavalo: plan.cavalo.nome,
  ...(viewer.showTrainer && {nomeTreinador: plan.treinador.nome}),
  dataInicio: toYmd(plan.dataInicio),
  dataFim: toYmd(plan.dataFim),
});

const toTreinamento = (
  record: TrainingRecordSummary,
  today: Date
): AgendaTreinamento => ({
  id: record._id.toHexString(),
  nomeTreinamento: record.treinamento?.titulo ?? "",
  nomeCavalo: record.cavalo?.nome ?? "",
  nomePlano: record.plano?.titulo ?? "",
  data: toYmd(record.dataPlanejada),
  status: statusOf(record, today),
});

const toTreinoDoDia = (
  record: TrainingRecordSummary,
  viewer: AgendaViewer
): AgendaTreinoDoDia => ({
  id: record._id.toHexString(),
  nomeTreinamento: record.treinamento?.titulo ?? "",
  nomeCavalo: record.cavalo?.nome ?? "",
  ...(viewer.showTrainer && {nomeTreinador: record.treinador?.nome ?? ""}),
  duracaoEstimadaMinutos: record.treinamento?.duracaoEstimadaMinutos ?? 0,
  nomePlano: record.plano?.titulo ?? "",
  role: viewer.roleOf(record),
});

const toExecucao = (record: RecentExecutionRecord): AgendaExecucao => ({
  id: record._id.toHexString(),
  nomeTreinamento: record.treinamento?.titulo ?? "",
  nomeCavalo: record.cavalo?.nome ?? "",
  data: record.dataExecucao ? toYmd(record.dataExecucao) : "",
  status: record.status,
});

/** Os sete dias da semana com a quantidade de treinos de cada um.
 * @param {DatePeriod} week Semana (segunda a segunda seguinte).
 * @param {AgendaTreinamento[]} trainings Treinamentos da semana.
 * @return {AgendaDia[]} Dias de segunda a domingo.
 */
function toDias(week: DatePeriod, trainings: AgendaTreinamento[]) {
  const counts = new Map<string, number>();
  for (const {data} of trainings) counts.set(data, (counts.get(data) ?? 0) + 1);
  return Array.from({length: 7}, (_, index): AgendaDia => {
    const data = toYmd(addDays(week.start, index));
    return {data, quantidadeTreinos: counts.get(data) ?? 0};
  });
}

/** Lê planos, semana, hoje e histórico em paralelo. Quando a semana pedida
 * contém hoje, os treinos de hoje saem dela, sem outra consulta.
 * @param {AgendaSources} sources Consultas do perfil.
 * @param {DatePeriod} week Semana pedida.
 * @param {Date} today Hoje (meia-noite UTC).
 * @return {Promise<AgendaData>} Dados da agenda.
 */
async function loadAgendaData(
  sources: AgendaSources,
  week: DatePeriod,
  today: Date
): Promise<AgendaData> {
  const todayInWeek = today >= week.start && today < week.end;
  const [plans, weekRecords, executions, otherTodayRecords] =
    await Promise.all([
      sources.plans(today),
      sources.records(week),
      sources.history(AGENDA_HISTORY_LIMIT),
      todayInWeek ?
        Promise.resolve([]) :
        sources.records({start: today, end: addDays(today, 1)}),
    ]);
  const todayRecords = todayInWeek ?
    weekRecords.filter(
      (record) => record.dataPlanejada.getTime() === today.getTime()
    ) :
    otherTodayRecords;
  return {plans, weekRecords, todayRecords, executions};
}

/** Monta a resposta comum aos dois perfis.
 * @param {AgendaViewer} viewer Perfil que consulta.
 * @param {DatePeriod} week Semana consultada.
 * @param {Date} today Hoje (meia-noite UTC).
 * @param {AgendaData} data Dados lidos do banco.
 * @return {AgendaResult} Dados da agenda.
 */
function buildAgenda(
  viewer: AgendaViewer,
  week: DatePeriod,
  today: Date,
  data: AgendaData
): AgendaResult {
  const treinamentos = data.weekRecords.map((record) =>
    toTreinamento(record, today)
  );
  return {
    role: viewer.role,
    hoje: toYmd(today),
    semana: {
      dataInicio: toYmd(week.start),
      dataFim: toYmd(addDays(week.end, -1)),
    },
    planosAtivos: {
      quantidade: data.plans.length,
      planos: data.plans.map((plan) => toPlano(plan, viewer)),
    },
    dias: toDias(week, treinamentos),
    treinamentos,
    treinosDoDia: {
      total: data.todayRecords.length,
      treinos: data.todayRecords.map((record) =>
        toTreinoDoDia(record, viewer)
      ),
    },
    historicoExecucoes: data.executions.map(toExecucao),
  };
}

/** Agenda do responsável: planos, treinos e execuções dos cavalos em que
 * ele tem alguma responsabilidade. O cargo em cada treino de hoje sai das
 * responsabilidades no cavalo do treino: ATLETA (mesmo que também
 * proprietário) ou PROPRIETARIO. A consulta é por cavalo, então a troca
 * de atleta não esconde nada.
 * @param {string} uid UID do responsável.
 * @param {AgendaFiltro} filtro Dia que escolhe a semana.
 * @param {Date} now Momento da consulta.
 * @return {Promise<AgendaResult>} Dados da agenda.
 */
export async function getGuardianAgenda(
  uid: string,
  filtro: AgendaFiltro,
  now: Date
): Promise<AgendaResult> {
  const guardian = await findGuardianHomeSource(uid);
  if (!guardian || guardian.situacaoCadastral !== "ATIVO") {
    throw new AppError("permission-denied", "Conta inativa ou inexistente.");
  }

  const athleteOf = new Set(
    guardian.cavalos
      .filter((horse) => horse.responsabilidades.includes("ATLETA"))
      .map((horse) => horse._id.toHexString())
  );
  const horseIds = guardian.cavalos.map((horse) => horse._id);
  const week = getWeekOf(filtro.data);
  const today = getDayStart(now);

  // Sem cavalos, nenhuma ida ao banco além da conta.
  const data = horseIds.length === 0 ?
    EMPTY_DATA :
    await loadAgendaData(
      {
        plans: (day) => findActivePlansByHorses(horseIds, day),
        records: (period) => findRecordsByHorses(horseIds, period),
        history: (limit) => findRecentExecutionsByHorses(horseIds, limit),
      },
      week,
      today
    );

  return buildAgenda(
    {
      role: "RESPONSAVEL",
      showTrainer: true,
      roleOf: (record) =>
        record.cavalo && athleteOf.has(record.cavalo._id.toHexString()) ?
          "ATLETA" :
          "PROPRIETARIO",
    },
    week,
    today,
    data
  );
}

/** Agenda do treinador: planos, treinos e execuções em que ele é o
 * treinador. O cargo é sempre TREINADOR.
 * @param {string} uid UID do treinador.
 * @param {AgendaFiltro} filtro Dia que escolhe a semana.
 * @param {Date} now Momento da consulta.
 * @return {Promise<AgendaResult>} Dados da agenda.
 */
export async function getTrainerAgenda(
  uid: string,
  filtro: AgendaFiltro,
  now: Date
): Promise<AgendaResult> {
  const week = getWeekOf(filtro.data);
  const today = getDayStart(now);
  const [, data] = await Promise.all([
    assertActiveAccount(uid, ROLES.trainer),
    loadAgendaData(
      {
        plans: (day) => findActivePlansByTrainer(uid, day),
        records: (period) => findRecordsByTrainer(uid, period),
        history: (limit) => findRecentExecutionsByTrainer(uid, limit),
      },
      week,
      today
    ),
  ]);

  return buildAgenda(
    {role: "TREINADOR", showTrainer: false, roleOf: () => "TREINADOR"},
    week,
    today,
    data
  );
}
