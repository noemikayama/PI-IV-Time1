// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Índice e renovação da cópia do treinamento nos planos em
// andamento.
//
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Planos ativos e não vencidos dos cavalos ou do treinador,
// usados pela agenda.
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Movido da feature de treinamentos para a feature de planos.
// Alteração: Índices, inserção, busca do plano ativo do cavalo e conclusão
// do plano.
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta do autor do plano ativo do cavalo, movida da feature
// de cavalos.
// -----------------------------------------------------------------------------

// Coleção 'planos'. Índices do DD 5.1; idx_planos_cavalo_ativo garante no
// banco no máximo um plano ATIVO por cavalo.
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
import type {TrainingSnapshot} from "../../training";
import type {ActivePlanSummary, PlanDocument} from "../types";

const PLAN_INDEXES: IndexDescription[] = [
  {key: {codigo: 1}, name: "codigo_unico", unique: true},
  {
    key: {"cavalo._id": 1},
    name: "idx_planos_cavalo_ativo",
    unique: true,
    partialFilterExpression: {status: "ATIVO"},
  },
  {
    key: {"treinador._id": 1, "status": 1},
    name: "idx_planos_treinador_status",
  },
  {
    key: {"planejamento.treinamento._id": 1},
    name: "idx_planos_treinamento",
  },
];

/** Garante os índices de 'planos'. Deve rodar fora da transação.
 * @return {Promise<void>} Resolvida quando os índices existirem.
 */
export const ensurePlanIndexes = (): Promise<void> =>
  ensureIndexesOnce(COLLECTIONS.Planos, PLAN_INDEXES);

/** Gera o código sequencial do plano (dentro da transação).
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<number>} Código do plano.
 */
export const nextPlanCode = (session: ClientSession): Promise<number> =>
  nextCode(COLLECTIONS.Planos, session);

/** Grava o plano. Um segundo plano ATIVO para o cavalo viola
 * idx_planos_cavalo_ativo (erro de chave duplicada).
 * @param {PlanDocument} plan Plano completo.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<void>} Resolvida quando o plano for gravado.
 */
export async function insertPlan(
  plan: PlanDocument,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  await db
    .collection<PlanDocument>(COLLECTIONS.Planos)
    .insertOne(plan, {session});
}

/** Busca o plano ATIVO do cavalo (idx_planos_cavalo_ativo).
 * @param {ObjectId} horseId _id do cavalo.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<Object|null>} _id e dataFim do plano, ou null.
 */
export async function findActivePlan(
  horseId: ObjectId,
  session: ClientSession
): Promise<Pick<PlanDocument, "_id" | "dataFim"> | null> {
  const db = await getDatabase();
  return db
    .collection<PlanDocument>(COLLECTIONS.Planos)
    .findOne(
      {"cavalo._id": horseId, "status": "ATIVO"},
      {projection: {_id: 1, dataFim: 1}, session}
    );
}

/** Conclui o plano ATIVO (CONCLUIDO). Os registros e o planoAtual do
 * cavalo são tratados por quem chama, na mesma transação.
 * @param {ObjectId} planId _id do plano.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<void>} Resolvida quando o plano for alterado.
 */
export async function concludePlan(
  planId: ObjectId,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  await db
    .collection<PlanDocument>(COLLECTIONS.Planos)
    .updateOne(
      {_id: planId, status: "ATIVO"},
      {$set: {status: "CONCLUIDO", atualizadoEm: new Date()}},
      {session}
    );
}

/** Indica se o treinador é autor do plano ATIVO do cavalo (RF05003).
 * @param {ObjectId} horseId _id do cavalo.
 * @param {string} trainerId UID do treinador.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<boolean>} Se existe plano ATIVO dele no cavalo.
 */
export async function isActivePlanAuthor(
  horseId: ObjectId,
  trainerId: string,
  session: ClientSession
): Promise<boolean> {
  const db = await getDatabase();
  const plan = await db.collection(COLLECTIONS.Planos).findOne(
    {
      "cavalo._id": horseId,
      "status": "ATIVO",
      "treinador._id": trainerId,
    },
    {projection: {_id: 1}, session}
  );
  return plan !== null;
}

/** Renova a cópia do treinamento nos itens ativos dos planos RASCUNHO e
 * ATIVO (edição do treinamento). Itens inativos e planos CONCLUIDO ou
 * CANCELADO guardam a versão antiga. Usa idx_planos_treinamento.
 * @param {TrainingSnapshot} snapshot Nova cópia do treinamento.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<void>} Resolvida quando os planos forem alterados.
 */
export async function refreshPlanTrainingSnapshots(
  snapshot: TrainingSnapshot,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  await db.collection<PlanDocument>(COLLECTIONS.Planos).updateMany(
    {
      "planejamento.treinamento._id": snapshot._id,
      "status": {$in: ["RASCUNHO", "ATIVO"]},
    },
    {
      $set: {
        "planejamento.$[item].treinamento": snapshot,
        "atualizadoEm": new Date(),
      },
    },
    {
      arrayFilters: [
        {"item.treinamento._id": snapshot._id, "item.ativo": true},
      ],
      session,
    }
  );
}
/** Planos ATIVO ainda não vencidos (dataFim >= hoje), em ordem de início.
 * Um plano vencido continua ATIVO até outro plano ser criado para o
 * cavalo, por isso o filtro de data.
 * @param {Document} owner Filtro dos cavalos ou do treinador.
 * @param {Date} today Hoje (meia-noite UTC, como getDayStart()).
 * @return {Promise<ActivePlanSummary[]>} Planos encontrados.
 */
async function findActivePlans(
  owner: Document,
  today: Date
): Promise<ActivePlanSummary[]> {
  const db = await getDatabase();
  return db
    .collection<PlanDocument>(COLLECTIONS.Planos)
    .find({...owner, status: "ATIVO", dataFim: {$gte: today}})
    .project<ActivePlanSummary>({
      "titulo": 1,
      "cavalo.nome": 1,
      "treinador.nome": 1,
      "dataInicio": 1,
      "dataFim": 1,
    })
    .sort({dataInicio: 1, _id: 1})
    .toArray();
}

// idx_planos_cavalo_ativo (parcial em status ATIVO).
export const findActivePlansByHorses = (horseIds: ObjectId[], today: Date) =>
  findActivePlans({"cavalo._id": {$in: horseIds}}, today);

// idx_planos_treinador_status.
export const findActivePlansByTrainer = (trainerId: string, today: Date) =>
  findActivePlans({"treinador._id": trainerId}, today);
