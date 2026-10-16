// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consultas de registros de treino para a home.
// -----------------------------------------------------------------------------

import type {Document, ObjectId} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import type {DatePeriod} from "../../../shared/utils/dates";
import type {
  DayTrainingRecord,
  ExecutionCount,
  FeedbackCount,
  HorseExecutionCounts,
} from "../types/trainingRecord";

// Mesma regra do dashboard: treino realizado = REALIZADO ou PARCIAL.
export const EXECUTED_STATUSES = ["REALIZADO", "PARCIAL"];

const NOT_CANCELED = {status: {$ne: "CANCELADO"}};

const DAY_PROJECTION = {
  "status": 1,
  "plano.titulo": 1,
  "cavalo.nome": 1,
  "treinador.nome": 1,
  "treinamento.titulo": 1,
  "treinamento.duracaoEstimadaMinutos": 1,
};

/** Retorna a coleção de registros de treino. */
async function getCollection() {
  const db = await getDatabase();
  return db.collection(COLLECTIONS.RegistrosTreino);
}

/** Cria os estágios de agregação das execuções de um período.
 * @param {string} dateField Campo de data usado na consulta.
 * @param {DatePeriod} period Período da consulta.
 * @return {Document[]} Estágios de agregação.
 */
function groupExecutions(dateField: string, period: DatePeriod): Document[] {
  return [
    {$match: {[dateField]: {$gte: period.start, $lt: period.end}}},
    {
      $group: {
        _id: null,
        total: {$sum: 1},
        executed: {
          $sum: {$cond: [{$in: ["$status", EXECUTED_STATUSES]}, 1, 0]},
        },
      },
    },
  ];
}

const toExecutionCount = (row?: Document | null): ExecutionCount => ({
  executed: row?.executed ?? 0,
  total: row?.total ?? 0,
});

/** Busca os registros não cancelados de um responsável em um dia.
 * @param {Document} owner Filtro do responsável ou treinador.
 * @param {DatePeriod} day Período do dia.
 */
async function findDayRecords(owner: Document, day: DatePeriod) {
  const records = await getCollection();
  return records
    .find({
      ...owner,
      ...NOT_CANCELED,
      dataPlanejada: {$gte: day.start, $lt: day.end},
    })
    .project<DayTrainingRecord>(DAY_PROJECTION)
    .sort({_id: 1})
    .toArray();
}

// idx_registros_cavalo_data. O registro grava o atleta como responsável; o
// proprietário consulta pelos seus cavalos. Por cavalo cobre os dois casos.
export const findDayRecordsByHorses = (
  horseIds: ObjectId[],
  day: DatePeriod
) => findDayRecords({"cavalo._id": {$in: horseIds}}, day);

export const findDayRecordsByTrainer = (
  trainerId: string,
  day: DatePeriod
) => findDayRecords({"treinador._id": trainerId}, day);

/** Conta as execuções dos cavalos na semana, no mês e desde sempre.
 * @param {ObjectId[]} horseIds IDs dos cavalos.
 * @param {DatePeriod} week Período da semana.
 * @param {DatePeriod} month Período do mês.
 */
export async function countHorseExecutions(
  horseIds: ObjectId[],
  week: DatePeriod,
  month: DatePeriod
): Promise<HorseExecutionCounts> {
  const records = await getCollection();
  const result = await records
    .aggregate([
      {$match: {"cavalo._id": {$in: horseIds}, ...NOT_CANCELED}},
      {
        $facet: {
          week: groupExecutions("dataPlanejada", week),
          month: groupExecutions("dataPlanejada", month),
          allTime: [
            {$match: {status: {$in: EXECUTED_STATUSES}}},
            {$count: "executed"},
          ],
        },
      },
    ])
    .next();

  return {
    week: toExecutionCount(result?.week?.[0]),
    month: toExecutionCount(result?.month?.[0]),
    allTimeExecuted: result?.allTime?.[0]?.executed ?? 0,
  };
}

/** Conta as execuções do treinador no período informado.
 * @param {string} trainerId UID do treinador.
 * @param {DatePeriod} period Período da consulta.
 */
export async function countTrainerExecutions(
  trainerId: string,
  period: DatePeriod
): Promise<ExecutionCount> {
  const records = await getCollection();
  const row = await records
    .aggregate([
      {$match: {"treinador._id": trainerId, ...NOT_CANCELED}},
      ...groupExecutions("dataPlanejada", period),
    ])
    .next();
  return toExecutionCount(row);
}

/** Conta registros executados e aqueles que incluem feedback.
 * @param {string} trainerId UID do treinador.
 * @param {DatePeriod} period Período da consulta.
 */
export async function countTrainerFeedbacks(
  trainerId: string,
  period: DatePeriod
): Promise<FeedbackCount> {
  const records = await getCollection();
  const row = await records
    .aggregate([
      {
        $match: {
          "treinador._id": trainerId,
          "status": {$in: EXECUTED_STATUSES},
          "dataExecucao": {$gte: period.start, $lt: period.end},
        },
      },
      {
        $group: {
          _id: null,
          executed: {$sum: 1},
          withFeedback: {
            $sum: {
              $cond: [{$eq: [{$type: "$feedback"}, "object"]}, 1, 0],
            },
          },
        },
      },
    ])
    .next();
  return {
    withFeedback: row?.withFeedback ?? 0,
    executed: row?.executed ?? 0,
  };
}
