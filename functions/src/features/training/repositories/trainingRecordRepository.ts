// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta se o treinamento foi agendado para algum dos cavalos
// (acesso aos detalhes do treinamento).
// Alteração: Índice por treinamento e renovação da cópia do treinamento nos
// registros PLANEJADO a partir de hoje (edição do treinamento).
//
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Registros de qualquer período (o dia na home, a semana na
// agenda), em ordem de data, com a data prevista, a de execução e o _id
// do cavalo na projeção.
// Alteração: Execuções mais recentes dos cavalos ou do treinador, para o
// histórico da agenda.
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Índices, inserção dos registros gerados pelo plano e
// encerramento dos registros PLANEJADO de um plano concluído.
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Nome do atleta (responsavel) na projeção do dia.
// Alteração: Treinos do dia de um cavalo no plano atual.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consultas de registros de treino para a home.
// -----------------------------------------------------------------------------

import type {
  ClientSession,
  Document,
  IndexDescription,
  ObjectId,
} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import {ensureIndexesOnce} from "../../../shared/database/indexes";
import {nextCode} from "../../../shared/database/sequence";
import {inPeriod} from "../../../shared/utils/dates";
import type {DatePeriod} from "../../../shared/utils/dates";
import type {
  ExecutionCount,
  FeedbackCount,
  HorseExecutionCounts,
  NewTrainingRecord,
  PerformedExercise,
  RecentExecutionRecord,
  TrainingRecordDocument,
  TrainingRecordSummary,
  TrainingRecordTraining,
} from "../types/trainingRecord";

// Índices do DD 5.1. O único em plano + item + data substitui o único em
// plano + item do DD: o item vale para vários dias da semana e gera um
// registro por data.
const RECORD_INDEXES: IndexDescription[] = [
  {key: {codigo: 1}, name: "codigo_unico", unique: true},
  {
    key: {"plano._id": 1, "itemPlanejamento": 1, "dataPlanejada": 1},
    name: "idx_registros_plano_item",
    unique: true,
  },
  {key: {"plano._id": 1, "status": 1}, name: "idx_registros_plano_status"},
  {
    key: {"cavalo._id": 1, "dataPlanejada": 1, "status": 1},
    name: "idx_registros_cavalo_data",
  },
  {
    key: {"treinador._id": 1, "dataPlanejada": 1},
    name: "idx_registros_treinador_data",
  },
  {
    key: {"treinador._id": 1, "status": 1, "dataExecucao": 1},
    name: "idx_registros_treinador_status",
  },
  {
    key: {"treinamento._id": 1, "status": 1, "dataPlanejada": 1},
    name: "idx_registros_treinamento",
  },
];

/** Garante os índices de 'registros_treino'. Deve rodar fora da transação.
 * @return {Promise<void>} Resolvida quando os índices existirem.
 */
export const ensureTrainingRecordIndexes = (): Promise<void> =>
  ensureIndexesOnce(COLLECTIONS.RegistrosTreino, RECORD_INDEXES);

/** Grava os registros com códigos sequenciais, reservados em bloco (uma
 * ida ao contador para todos), na ordem recebida.
 * @param {NewTrainingRecord[]} records Registros sem o código.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<void>} Resolvida quando os registros forem gravados.
 */
export async function insertTrainingRecords(
  records: NewTrainingRecord[],
  session: ClientSession
): Promise<void> {
  if (records.length === 0) return;
  const db = await getDatabase();
  const last = await nextCode(
    COLLECTIONS.RegistrosTreino,
    session,
    records.length
  );
  const first = last - records.length + 1;
  await db
    .collection<TrainingRecordDocument>(COLLECTIONS.RegistrosTreino)
    .insertMany(
      records.map((record, index) => ({...record, codigo: first + index})),
      {session}
    );
}

/** Na conclusão do plano, os registros ainda PLANEJADO passam para
 * NAO_REALIZADO (DD 5.2). Usa idx_registros_plano_status.
 * @param {ObjectId} planId _id do plano.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<void>} Resolvida quando os registros forem alterados.
 */
export async function closePlannedRecords(
  planId: ObjectId,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  await db.collection(COLLECTIONS.RegistrosTreino).updateMany(
    {"plano._id": planId, "status": "PLANEJADO"},
    {$set: {status: "NAO_REALIZADO", atualizadoEm: new Date()}},
    {session}
  );
}

// Mesma regra do dashboard: treino realizado = REALIZADO ou PARCIAL.
export const EXECUTED_STATUSES = ["REALIZADO", "PARCIAL"];

const NOT_CANCELED = {status: {$ne: "CANCELADO"}};

const SUMMARY_PROJECTION = {
  "status": 1,
  "dataPlanejada": 1,
  "dataExecucao": 1,
  "cavalo._id": 1,
  "plano.titulo": 1,
  "responsavel.nome": 1,
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

/** Busca os registros não cancelados com data prevista no período, em
 * ordem de data (no mesmo dia, de criação).
 * @param {Document} owner Filtro do responsável ou treinador.
 * @param {DatePeriod} period Período da consulta (o dia ou a semana).
 */
async function findRecords(owner: Document, period: DatePeriod) {
  const records = await getCollection();
  return records
    .find({...owner, ...NOT_CANCELED, ...inPeriod("dataPlanejada", period)})
    .project<TrainingRecordSummary>(SUMMARY_PROJECTION)
    .sort({dataPlanejada: 1, _id: 1})
    .toArray();
}

// idx_registros_cavalo_data. O registro grava o atleta como responsável; o
// proprietário consulta pelos seus cavalos. Por cavalo cobre os dois casos.
export const findRecordsByHorses = (
  horseIds: ObjectId[],
  period: DatePeriod
) => findRecords({"cavalo._id": {$in: horseIds}}, period);

// Aba "Plano atual": só os registros do plano ATIVO do cavalo. Usa
// idx_registros_cavalo_data.
export const findDayRecordsByHorsePlan = (
  horseId: ObjectId,
  planId: ObjectId,
  day: DatePeriod
) => findRecords({"cavalo._id": horseId, "plano._id": planId}, day);

// idx_registros_treinador_data.
export const findRecordsByTrainer = (
  trainerId: string,
  period: DatePeriod
) => findRecords({"treinador._id": trainerId}, period);

/** Execuções (REALIZADO ou PARCIAL) mais recentes primeiro.
 * @param {Document} owner Filtro dos cavalos ou do treinador.
 * @param {number} limit Quantidade máxima.
 */
async function findRecentExecutions(owner: Document, limit: number) {
  const records = await getCollection();
  return records
    .find({...owner, status: {$in: EXECUTED_STATUSES}})
    .project<RecentExecutionRecord>({
      "status": 1,
      "dataExecucao": 1,
      "cavalo.nome": 1,
      "treinamento.titulo": 1,
    })
    .sort({dataExecucao: -1, _id: -1})
    .limit(limit)
    .toArray();
}

// idx_registros_cavalo_data filtra pelos cavalos; a ordenação por
// dataExecucao é feita em memória sobre as execuções deles.
export const findRecentExecutionsByHorses = (
  horseIds: ObjectId[],
  limit: number
) => findRecentExecutions({"cavalo._id": {$in: horseIds}}, limit);

// idx_registros_treinador_status (treinador, status, dataExecucao).
export const findRecentExecutionsByTrainer = (
  trainerId: string,
  limit: number
) => findRecentExecutions({"treinador._id": trainerId}, limit);

/** Diz se existe registro de treino (de qualquer status) do treinamento
 * para algum dos cavalos. Usa o prefixo de idx_registros_cavalo_data.
 * @param {ObjectId} trainingId _id do treinamento de origem.
 * @param {ObjectId[]} horseIds IDs dos cavalos.
 * @return {Promise<boolean>} Se algum registro foi encontrado.
 */
export async function hasTrainingRecordForHorses(
  trainingId: ObjectId,
  horseIds: ObjectId[]
): Promise<boolean> {
  if (horseIds.length === 0) return false;
  const records = await getCollection();
  const record = await records.findOne(
    {"cavalo._id": {$in: horseIds}, "treinamento._id": trainingId},
    {projection: {_id: 1}}
  );
  return record !== null;
}

/** Renova a cópia do treinamento nos registros ainda PLANEJADO a partir
 * do dia informado e sem nenhum exercício marcado (todos PENDENTE), porque
 * a renovação volta os exercícios a PENDENTE. Os anteriores, os já
 * começados e os executados ou encerrados guardam a versão com que foram
 * agendados. Usa idx_registros_treinamento.
 * @param {ObjectId} trainingId _id do treinamento de origem.
 * @param {Date} from Primeiro dia alterado (meia-noite UTC).
 * @param {object} copy 'treinamento' e 'exercicios' novos do registro.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<void>} Resolvida quando os registros forem alterados.
 */
export async function refreshPlannedRecordsTraining(
  trainingId: ObjectId,
  from: Date,
  copy: {treinamento: TrainingRecordTraining; exercicios: PerformedExercise[]},
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  await db
    .collection<TrainingRecordDocument>(COLLECTIONS.RegistrosTreino)
    .updateMany(
      {
        "treinamento._id": trainingId,
        "status": "PLANEJADO",
        "dataPlanejada": {$gte: from},
        "exercicios": {$not: {$elemMatch: {realizacao: {$ne: "PENDENTE"}}}},
      },
      {$set: {...copy, atualizadoEm: new Date()}},
      {session}
    );
}

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
