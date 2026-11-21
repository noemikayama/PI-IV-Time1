// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Lista de feedbacks opcional, feedback.data filtrado pelo
// instante de São Paulo, filtro de período compartilhado, poda dos
// registros fora da janela antes do $facet e contagens de planos e
// avaliações do treinador.
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Agregação dos indicadores e das listas do dashboard.
// -----------------------------------------------------------------------------

// Coleções 'registros_treino' (idx_registros_cavalo_data: cavalo._id,
// dataPlanejada, status), 'planos' (idx_planos_treinador_status) e
// 'avaliacoes'.
import type {ObjectId} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import {inPeriod} from "../../../shared/utils/dates";
import type {DatePeriod} from "../../../shared/utils/dates";
import {EXECUTED_STATUSES} from "../../training";
import type {
  DashboardAgregado,
  DashboardIndicadoresRow,
  DashboardWindow,
  FeedbackRecenteRow,
  PlanosStatusRow,
  TreinoRecenteRow,
} from "../types";

// Registros cancelados saem de todos os cálculos (DD 2.9).
const NOT_CANCELED = {status: {$ne: "CANCELADO"}};

// O treino conta para o cumprimento quando foi executado e tem as duas
// durações: sem elas a razão não existe.
const HAS_RATIO = {
  $and: [
    {$in: ["$status", EXECUTED_STATUSES]},
    {$gt: ["$treinamento.duracaoEstimadaMinutos", 0]},
    {$gt: ["$duracaoEfetivaMinutos", 0]},
  ],
};

// Razão entre duração efetiva e estimada, limitada a 100% (RF10004/RF10005).
const RATIO = {
  $cond: [
    HAS_RATIO,
    {
      $min: [
        1,
        {
          $divide: [
            "$duracaoEfetivaMinutos",
            "$treinamento.duracaoEstimadaMinutos",
          ],
        },
      ],
    },
    0,
  ],
};

// Formato devolvido pelo $facet: cada ramo é uma lista.
type DashboardFacet = {
    indicadores: DashboardIndicadoresRow[];
    ultimosTreinos: TreinoRecenteRow[];
    // Ausente quando o ramo de feedbacks não é pedido.
    ultimosFeedbacks?: FeedbackRecenteRow[];
};

const EMPTY_INDICATORS: DashboardIndicadoresRow = {
  previstos: 0,
  realizados: 0,
  parciais: 0,
  somaCumprimento: 0,
  treinosConsiderados: 0,
};

const EMPTY_RESULT: DashboardAgregado = {
  indicadores: EMPTY_INDICATORS,
  ultimosTreinos: [],
  ultimosFeedbacks: [],
};

/** Agrega os indicadores e as listas do dashboard em uma única consulta.
 * Os indicadores usam 'dataPlanejada' (o que estava previsto no período) e
 * as listas usam a data do próprio evento ('dataExecucao' e 'feedback.data').
 * @param {ObjectId[]} horseIds Cavalos aos quais o usuário tem acesso.
 * @param {DashboardWindow} window Janela do período.
 * @param {number} limit Tamanho das listas de recentes.
 * @param {boolean} withFeedbacks Se a lista de feedbacks é montada; o
 * treinador não a exibe e pula esse ramo.
 * @return {Promise<DashboardAgregado>} Números e listas do período.
 */
export async function aggregateHorseDashboard(
  horseIds: ObjectId[],
  window: DashboardWindow,
  limit: number,
  withFeedbacks = true
): Promise<DashboardAgregado> {
  if (horseIds.length === 0) return EMPTY_RESULT;

  const {range, instants} = window;
  // O $facet não usa índice e recebe tudo o que passar do $match inicial.
  // Sem esta poda, um filtro SEMANAL levaria todo o histórico dos cavalos
  // para a memória; cada ramo ainda aplica o seu próprio filtro de data.
  const inSomeBranch = [
    inPeriod("dataPlanejada", range),
    inPeriod("dataExecucao", range),
    ...(withFeedbacks ? [inPeriod("feedback.data", instants)] : []),
  ];
  const feedbackBranch = {
    ultimosFeedbacks: [
      {
        $match: {
          "feedback": {$exists: true},
          ...inPeriod("feedback.data", instants),
        },
      },
      {$sort: {"feedback.data": -1, "_id": -1}},
      {$limit: limit},
      {
        $project: {
          "feedback.data": 1,
          "treinamento.titulo": 1,
          "plano.titulo": 1,
        },
      },
    ],
  };

  const db = await getDatabase();
  const result = await db
    .collection(COLLECTIONS.RegistrosTreino)
    .aggregate<DashboardFacet>([
      {
        $match: {
          "cavalo._id": {$in: horseIds},
          ...NOT_CANCELED,
          "$or": inSomeBranch,
        },
      },
      {
        $facet: {
          indicadores: [
            {$match: inPeriod("dataPlanejada", range)},
            {
              $group: {
                _id: null,
                previstos: {$sum: 1},
                realizados: {
                  $sum: {$cond: [{$eq: ["$status", "REALIZADO"]}, 1, 0]},
                },
                parciais: {
                  $sum: {$cond: [{$eq: ["$status", "PARCIAL"]}, 1, 0]},
                },
                somaCumprimento: {$sum: RATIO},
                treinosConsiderados: {$sum: {$cond: [HAS_RATIO, 1, 0]}},
              },
            },
          ],
          ultimosTreinos: [
            {
              $match: {
                "status": {$in: EXECUTED_STATUSES},
                ...inPeriod("dataExecucao", range),
              },
            },
            // O _id desempata execuções do mesmo dia (a data não tem hora).
            {$sort: {dataExecucao: -1, _id: -1}},
            {$limit: limit},
            {
              $project: {
                "dataExecucao": 1,
                "treinamento.titulo": 1,
                "cavalo.nome": 1,
                "plano.titulo": 1,
              },
            },
          ],
          ...(withFeedbacks ? feedbackBranch : {}),
        },
      },
    ])
    .next();

  const row = result?.indicadores?.[0];
  return {
    indicadores: {
      previstos: row?.previstos ?? 0,
      realizados: row?.realizados ?? 0,
      parciais: row?.parciais ?? 0,
      somaCumprimento: row?.somaCumprimento ?? 0,
      treinosConsiderados: row?.treinosConsiderados ?? 0,
    },
    ultimosTreinos: result?.ultimosTreinos ?? [],
    ultimosFeedbacks: result?.ultimosFeedbacks ?? [],
  };
}

const PLAN_STATUS_FIELD: Record<string, keyof PlanosStatusRow> = {
  ATIVO: "ativos",
  CONCLUIDO: "concluidos",
  CANCELADO: "cancelados",
  RASCUNHO: "rascunhos",
};

/** Conta os planos criados pelo treinador no período, pelo status atual.
 * Usa idx_planos_treinador_status (treinador._id, status).
 * @param {string} trainerId UID do treinador.
 * @param {DatePeriod} createdIn Período de 'criadoEm'.
 * @return {Promise<PlanosStatusRow>} Quantidade por status.
 */
export async function countTrainerPlansByStatus(
  trainerId: string,
  createdIn: DatePeriod
): Promise<PlanosStatusRow> {
  const db = await getDatabase();
  const rows = await db
    .collection(COLLECTIONS.Planos)
    .aggregate<{_id: string; total: number}>([
      {
        $match: {
          "treinador._id": trainerId,
          ...inPeriod("criadoEm", createdIn),
        },
      },
      {$group: {_id: "$status", total: {$sum: 1}}},
    ])
    .toArray();

  const counts: PlanosStatusRow = {
    ativos: 0,
    concluidos: 0,
    cancelados: 0,
    rascunhos: 0,
  };
  for (const row of rows) {
    const field = PLAN_STATUS_FIELD[row._id];
    if (field) counts[field] = row.total;
  }
  return counts;
}

/** Conta as avaliações feitas pelo treinador no período. O DD não define
 * índice por treinador em 'avaliacoes' (só idx_avaliacoes_cavalo_data); com
 * volume, vale criar um em (treinador._id, data).
 * @param {string} trainerId UID do treinador.
 * @param {DatePeriod} range Período de 'data' (calendário).
 * @return {Promise<number>} Quantidade de avaliações.
 */
export async function countTrainerEvaluations(
  trainerId: string,
  range: DatePeriod
): Promise<number> {
  const db = await getDatabase();
  return db
    .collection(COLLECTIONS.Avaliacoes)
    .countDocuments({"treinador._id": trainerId, ...inPeriod("data", range)});
}
