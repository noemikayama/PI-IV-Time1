// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Visualização do plano de treinamento para o treinador e o
// responsável.
// Alteração: Acesso, status e permissões movidos para planAccess,
// compartilhado com o cancelamento.
// Alteração: Treinos por dia, para preencher a tela de edição.
// Alteração: Treinos lidos dos registros de treino, para a edição do plano
// não reescrever o passado; o planejamento completa os dias sem registro.
// -----------------------------------------------------------------------------

// Os treinos saem dos registros do plano (a cópia guardada em cada um) e o
// planejamento só completa os dias que ainda não têm registro. Nenhuma
// consulta a treinamentos, exercícios ou avaliações.
import type {ClientSession} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import {
  addDays,
  getDayStart,
  getWeekOf,
  toYmd,
} from "../../../shared/utils/dates";
import {assertActiveAccount} from "../../horses";
import {findPlanSessionRecords} from "../../training";
import type {PlanSessionRecord, TrainingSnapshot} from "../../training";
import {findPlanById} from "../repositories/planRepository";
import {DIAS_SEMANA} from "../types";
import type {
  DiaSemana,
  PlanDayTrainingView,
  PlanDocument,
  PlanIdInput,
  PlanningItem,
  PlanSessionView,
  TrainingPlanDetailsResult,
} from "../types";
import {
  displayedStatus,
  PLAN_NOT_FOUND_MESSAGE,
  planPermissions,
  resolvePlanViewer,
} from "./planAccess";
import type {PlanViewer} from "./planAccess";
import {listPlannedDates} from "./planSchedule";
import type {PlannedDate} from "./planSchedule";

// Datas de calendário são meia-noite UTC: formatar em UTC mantém o dia.
// Reutilizados entre chamadas: criar um Intl.DateTimeFormat é caro.
const LONG_DATE = new Intl.DateTimeFormat("pt-BR", {
  weekday: "long",
  day: "numeric",
  month: "long",
  year: "numeric",
  timeZone: "UTC",
});
const WEEKDAY = new Intl.DateTimeFormat("pt-BR", {
  weekday: "long",
  timeZone: "UTC",
});

const capitalize = (text: string): string =>
  text.charAt(0).toUpperCase() + text.slice(1);

// Campos do treinamento mostrados no card (da cópia no item ou no registro).
type SessionTraining = Pick<
    TrainingSnapshot,
    "codigo" | "titulo" | "descricao" | "duracaoEstimadaMinutos"
>;

/** Monta o card do treino de um dia.
 * @param {Date} date Data do treino (meia-noite UTC).
 * @param {SessionTraining} training Cópia do treinamento.
 * @param {string[]} exercises Nomes dos exercícios, em ordem.
 * @return {PlanSessionView} Card do treino.
 */
function toSession(
  date: Date,
  training: SessionTraining,
  exercises: string[]
): PlanSessionView {
  return {
    data: toYmd(date),
    dataPorExtenso: capitalize(LONG_DATE.format(date)),
    diaSemana: capitalize(WEEKDAY.format(date)),
    treinamento: {
      codigo: String(training.codigo),
      titulo: training.titulo,
      duracaoEstimadaMinutos: training.duracaoEstimadaMinutos,
      descricao: training.descricao ?? "",
      exercicios: exercises,
    },
  };
}

/** Primeiro dia que o planejamento completa: hoje; num plano cancelado, o
 * dia do cancelamento (o plano não muda depois dele), para continuar
 * mostrando as datas que estavam previstas.
 * @param {PlanDocument} plan Plano.
 * @param {Date} today Hoje (meia-noite UTC).
 * @return {Date} Primeiro dia completado pelo planejamento.
 */
export const planningCutoff = (
  plan: Pick<PlanDocument, "status" | "atualizadoEm">,
  today: Date
): Date =>
  plan.status === "CANCELADO" ? getDayStart(plan.atualizadoEm) : today;

/** Treinos do plano, em ordem de data. Os registros (sem os CANCELADO)
 * mostram o que de fato foi agendado em cada dia, então uma edição não
 * reescreve o passado. O planejamento completa, a partir do corte, os dias
 * sem registro (plano cancelado ou ainda sem registros).
 * @param {PlanDocument} plan Plano.
 * @param {PlanSessionRecord[]} records Registros do plano, sem CANCELADO.
 * @param {Date} today Hoje (meia-noite UTC).
 * @return {PlanSessionView[]} Cards em ordem de data.
 */
export function listPlanSessions(
  plan: PlanDocument,
  records: PlanSessionRecord[],
  today: Date
): PlanSessionView[] {
  const recordDays = new Set(
    records.map((record) => record.dataPlanejada.getTime())
  );
  const planned = listPlannedDates(plan, planningCutoff(plan, today))
    .filter(({data}) => !recordDays.has(data.getTime()))
    .map(({data, item}: PlannedDate) => toSession(
      data,
      item.treinamento,
      item.treinamento.exercicios.map((exercise) => exercise.nome)
    ));
  return [
    ...records.map((record) => toSession(
      record.dataPlanejada,
      record.treinamento,
      record.exercicios.map(({exercicio}) => exercicio.nome)
    )),
    ...planned,
  ].sort((a, b) => a.data.localeCompare(b.data));
}

/** Treino de cada dia, pelos itens ativos do planejamento.
 * @param {PlanningItem[]} planning Planejamento do plano.
 * @return {Record<DiaSemana, PlanDayTrainingView|null>} Treino por dia.
 */
function toTrainingsByDay(
  planning: PlanningItem[]
): Record<DiaSemana, PlanDayTrainingView | null> {
  const byDay = Object.fromEntries(
    DIAS_SEMANA.map((dia) => [dia, null])
  ) as Record<DiaSemana, PlanDayTrainingView | null>;
  for (const item of planning) {
    if (!item.ativo) continue;
    const {_id, codigo, titulo, duracaoEstimadaMinutos} = item.treinamento;
    for (const dia of item.diasSemana) {
      byDay[dia] = {
        id: _id.toHexString(),
        codigo,
        titulo,
        duracaoEstimadaMinutos,
      };
    }
  }
  return byDay;
}

/** Monta a tela do plano (sem banco). Os treinos da semana ficam vazios
 * enquanto o plano não começou; "Ver tudo" traz todas as datas, mesmo de
 * um plano cancelado.
 * @param {PlanDocument} plan Plano lido.
 * @param {PlanViewer} viewer Quem consulta.
 * @param {Date} today Hoje (meia-noite UTC, como getDayStart()).
 * @param {PlanSessionRecord[]} records Registros do plano, sem CANCELADO.
 * @return {TrainingPlanDetailsResult} Dados da tela.
 */
export function buildTrainingPlanDetails(
  plan: PlanDocument,
  viewer: PlanViewer,
  today: Date,
  records: PlanSessionRecord[]
): TrainingPlanDetailsResult {
  const status = displayedStatus(plan, today);
  const week = getWeekOf(today);
  const weekStart = toYmd(week.start);
  const weekEnd = toYmd(week.end);

  const all = listPlanSessions(plan, records, today);
  const thisWeek = today < plan.dataInicio ?
    [] :
    all.filter(({data}) => data >= weekStart && data < weekEnd);

  const evaluation = plan.avaliacaoInicial;
  return {
    role: viewer.role,
    plano: {
      id: plan._id.toHexString(),
      codigo: plan.codigo,
      titulo: plan.titulo,
      objetivo: plan.objetivo,
      dataInicio: toYmd(plan.dataInicio),
      dataFim: toYmd(plan.dataFim),
      status,
    },
    cavalo: {id: plan.cavalo._id.toHexString(), nome: plan.cavalo.nome},
    ...(!viewer.isAuthor && {nomeTreinador: plan.treinador.nome}),
    permissoes: planPermissions(viewer.role, status),
    avaliacao: evaluation ? {
      id: evaluation._id.toHexString(),
      codigo: evaluation.codigo,
      data: evaluation.data,
      nomeCavalo: plan.cavalo.nome,
    } : null,
    treinosDaSemana: {
      dataInicio: weekStart,
      dataFim: toYmd(addDays(week.end, -1)),
      total: thisWeek.length,
      treinos: thisWeek,
    },
    todosOsTreinos: {total: all.length, treinos: all},
    treinosPorDia: toTrainingsByDay(plan.planejamento),
  };
}

/** Lê os registros do plano e monta a tela. Usado também pela edição e
 * pelo cancelamento, dentro da transação, para devolver o plano alterado.
 * @param {PlanDocument} plan Plano (já alterado, se for o caso).
 * @param {PlanViewer} viewer Quem consulta.
 * @param {Date} today Hoje (meia-noite UTC).
 * @param {ClientSession} session Sessão da transação, se houver.
 * @return {Promise<TrainingPlanDetailsResult>} Dados da tela.
 */
export async function loadTrainingPlanDetails(
  plan: PlanDocument,
  viewer: PlanViewer,
  today: Date,
  session?: ClientSession
): Promise<TrainingPlanDetailsResult> {
  const records = await findPlanSessionRecords(plan._id, session);
  return buildTrainingPlanDetails(plan, viewer, today, records);
}

/** Visualização do plano: uma resposta para os dois perfis, com a semana
 * atual e todas as datas do plano ("Ver tudo").
 * @param {AuthenticatedUser} user Usuário autenticado.
 * @param {PlanIdInput} input _id do plano.
 * @param {Date} now Momento da consulta.
 * @return {Promise<TrainingPlanDetailsResult>} Dados da tela.
 */
export async function getTrainingPlanDetailsService(
  user: AuthenticatedUser,
  input: PlanIdInput,
  now = new Date()
): Promise<TrainingPlanDetailsResult> {
  // Conta inativa prevalece: a leitura do plano nunca falha (devolve null).
  const [plan] = await Promise.all([
    findPlanById(input.planoId),
    assertActiveAccount(user.uid, user.role),
  ]);
  if (!plan) throw new AppError("not-found", PLAN_NOT_FOUND_MESSAGE);

  // O acesso e os registros dependem só do plano: lidos em paralelo.
  const [viewer, records] = await Promise.all([
    resolvePlanViewer(user, plan),
    findPlanSessionRecords(plan._id),
  ]);
  return buildTrainingPlanDetails(plan, viewer, getDayStart(now), records);
}
