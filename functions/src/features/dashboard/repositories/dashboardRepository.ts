// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Agregação dos indicadores e das listas do dashboard.
// -----------------------------------------------------------------------------

// Coleção 'registros_treino'. Usa idx_registros_cavalo_data
// (cavalo._id, dataPlanejada, status).
import type {Document, ObjectId} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import type {DatePeriod} from "../../../shared/utils/dates";
import {EXECUTED_STATUSES} from "../../training";
import type {
  DashboardAgregado,
  DashboardIndicadoresRow,
  FeedbackRecenteRow,
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
    ultimosFeedbacks: FeedbackRecenteRow[];
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

/** Monta o filtro de data de um campo; sem período, não filtra.
 * @param {string} field Campo de data.
 * @param {DatePeriod} range Intervalo do filtro ou null.
 * @return {Document} Trecho do $match.
 */
function inPeriod(field: string, range: DatePeriod | null): Document {
  return range ? {[field]: {$gte: range.start, $lt: range.end}} : {};
}

/** Agrega os indicadores e as listas do dashboard em uma única consulta.
 * Os indicadores usam 'dataPlanejada' (o que estava previsto no período) e
 * as listas usam a data do próprio evento ('dataExecucao' e 'feedback.data').
 * @param {ObjectId[]} horseIds Cavalos aos quais o usuário tem acesso.
 * @param {DatePeriod} range Intervalo do filtro ou null para desde sempre.
 * @param {number} limit Tamanho das listas de recentes.
 * @return {Promise<DashboardAgregado>} Números e listas do período.
 */
export async function aggregateHorseDashboard(
  horseIds: ObjectId[],
  range: DatePeriod | null,
  limit: number
): Promise<DashboardAgregado> {
  if (horseIds.length === 0) return EMPTY_RESULT;

  const db = await getDatabase();
  const result = await db
    .collection(COLLECTIONS.RegistrosTreino)
    .aggregate<DashboardFacet>([
      {$match: {"cavalo._id": {$in: horseIds}, ...NOT_CANCELED}},
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
          ultimosFeedbacks: [
            {
              $match: {
                "feedback": {$exists: true},
                ...inPeriod("feedback.data", range),
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
