// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cadastro, edição e consulta de cavalos; índice do microchip e
// atualização das cópias resumidas em responsaveis e treinadores.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta dos treinadores dos cavalos para a home.
// -----------------------------------------------------------------------------

// Coleção 'cavalos'. Índice único em 'codigo' (microchip).
import type {ClientSession, ObjectId, UpdateFilter} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import {AppError} from "../../../shared/errors/AppError";
import {isDuplicateKeyError} from "../../../shared/errors/isDuplicateKeyError";
import type {
  GuardianHorseRef,
  HorseDocument,
  HorseTrainerRef,
} from "../types";

// Parte de 'responsaveis' que esta feature mantém (_id é o UID do Firebase).
type GuardianHorses = {
    _id: string;
    situacaoCadastral: "ATIVO" | "INATIVO";
    cavalos: GuardianHorseRef[];
    atualizadoEm: Date;
};

// Criado uma vez por processo; createIndex não altera um índice existente.
let indexesReady: Promise<void> | undefined;

/** Garante o índice único do microchip. Deve rodar fora da transação.
 * @return {Promise<void>} Resolvida quando o índice existir.
 */
export function ensureHorseIndexes(): Promise<void> {
  if (!indexesReady) {
    indexesReady = getDatabase()
      .then((db) =>
        db
          .collection(COLLECTIONS.Cavalos)
          .createIndex({codigo: 1}, {unique: true, name: "codigo_unico"})
      )
      .then(() => undefined)
      .catch((error) => {
        // Permite nova tentativa na próxima chamada.
        indexesReady = undefined;
        throw error;
      });
  }
  return indexesReady;
}

/** Grava o cavalo; microchip repetido vira 'already-exists'.
 * @param {HorseDocument} horse Documento completo do cavalo.
 * @param {ClientSession} session Sessão da transação.
 */
export async function insertHorse(
  horse: HorseDocument,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  try {
    await db
      .collection<HorseDocument>(COLLECTIONS.Cavalos)
      .insertOne(horse, {session});
  } catch (error) {
    if (isDuplicateKeyError(error)) {
      throw new AppError("already-exists", "Microchip já cadastrado.");
    }
    throw error;
  }
}

/** Busca um cavalo ativo pelo _id.
 * @param {ObjectId} id _id do cavalo.
 */
export async function findActiveHorseById(
  id: ObjectId
): Promise<HorseDocument | null> {
  const db = await getDatabase();
  return db
    .collection<HorseDocument>(COLLECTIONS.Cavalos)
    .findOne({_id: id, situacaoCadastral: "ATIVO"});
}

/** Aplica a edição e devolve o documento atualizado.
 * @param {ObjectId} id _id do cavalo.
 * @param {UpdateFilter} update Alterações ($set/$unset).
 * @param {ClientSession} session Sessão da transação.
 */
export async function updateHorseDocument(
  id: ObjectId,
  update: UpdateFilter<HorseDocument>,
  session: ClientSession
): Promise<HorseDocument | null> {
  const db = await getDatabase();
  return db
    .collection<HorseDocument>(COLLECTIONS.Cavalos)
    .findOneAndUpdate(
      {_id: id, situacaoCadastral: "ATIVO"},
      update,
      {returnDocument: "after", session}
    );
}

/** Acrescenta o cavalo à lista resumida do responsável ativo.
 * @param {string} uid UID do responsável.
 * @param {GuardianHorseRef} horse Referência resumida do cavalo.
 * @param {ClientSession} session Sessão da transação.
 */
export async function addHorseToGuardian(
  uid: string,
  horse: GuardianHorseRef,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  const result = await db
    .collection<GuardianHorses>(COLLECTIONS.Responsaveis)
    .updateOne(
      {_id: uid, situacaoCadastral: "ATIVO"},
      {$push: {cavalos: horse}, $set: {atualizadoEm: new Date()}},
      {session}
    );
  // Lançar aqui aborta a transação e desfaz a inserção do cavalo.
  if (result.matchedCount === 0) {
    throw new AppError("permission-denied", "Conta inativa ou inexistente.");
  }
}

/** Atualiza o nome do cavalo nas cópias de responsaveis e treinadores.
 * Só altera as cópias com nome diferente, então pode ser chamada sempre.
 * @param {ObjectId} id _id do cavalo.
 * @param {string} nome Novo nome.
 * @param {ClientSession} session Sessão da transação.
 */
export async function renameHorseRefs(
  id: ObjectId,
  nome: string,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  const filter = {cavalos: {$elemMatch: {_id: id, nome: {$ne: nome}}}};
  const update = {
    $set: {"cavalos.$[cavalo].nome": nome, "atualizadoEm": new Date()},
  };
  const options = {arrayFilters: [{"cavalo._id": id}], session};

  const collections = [COLLECTIONS.Responsaveis, COLLECTIONS.Treinadores];
  await Promise.all(
    collections.map((collection) =>
      db.collection(collection).updateMany(filter, update, options)
    )
  );
}

/** Lista os treinadores dos cavalos, em ordem alfabética.
 * @param {ObjectId[]} horseIds IDs dos cavalos.
 * @param {number} limit Quantidade máxima de treinadores.
 */
export async function findTrainersOfHorses(
  horseIds: ObjectId[],
  limit: number
): Promise<HorseTrainerRef[]> {
  if (horseIds.length === 0) return [];

  const db = await getDatabase();
  return db
    .collection(COLLECTIONS.Cavalos)
    .aggregate<HorseTrainerRef>([
      {$match: {_id: {$in: horseIds}}},
      {$unwind: "$treinadores"},
      {
        $group: {
          _id: "$treinadores._id",
          nome: {$first: "$treinadores.nome"},
        },
      },
      {$sort: {nome: 1}},
      {$limit: limit},
    ])
    .toArray();
}
