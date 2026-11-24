// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: _id dos cavalos ativos vinculados a uma pessoa, usados pelo
// acesso ao exercício.
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Microchip repetido na edição vira 'already-exists'; nome e
// microchip copiados em todas as coleções que guardam o cavalo, em
// operações sequenciais na sessão.
// Alteração: Índices de proprietário, atleta e treinadores; leitura do
// cavalo na transação; consulta dos cavalos da lista.
// Alteração: Inclusão de item nas listas de saúde com $push e exclusão
// lógica do cavalo.
// Alteração: Remoção de imagem restrita a cavalo ativo (C11).
// Alteração: Trecho de 'responsaveis' tipado pelo GuardianDocument.
// Alteração: Repository só da coleção 'cavalos': addHorseToGuardian e
// syncHorseRefs movidos para horseSummaryRepository.ts; recebe
// findClientsFromHorses; conversão única do microchip repetido; filtro de
// cavalo ativo em findTrainersOfHorses.
// Alteração: Índices criados pelo helper compartilhado ensureIndexesOnce.
// Alteração: HorseListSource movido para types/horse.ts.
//
// Data: 27/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Inclusão e remoção dos caminhos das imagens do cavalo.
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

// Coleção 'cavalos', a fonte da verdade do cavalo. Índice único em 'codigo'
// (microchip) e índices do DD em proprietario._id, atleta._id e
// treinadores._id. As cópias do cavalo em outras coleções ficam em
// horseSummaryRepository.ts.
import type {
  ClientSession,
  Filter,
  IndexDescription,
  ObjectId,
  UpdateFilter,
} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import {ensureIndexesOnce} from "../../../shared/database/indexes";
import {AppError} from "../../../shared/errors/AppError";
import {isDuplicateKeyError} from "../../../shared/errors/isDuplicateKeyError";
import type {
  AccountRef,
  HorseDocument,
  HorseHealthEntryInput,
  HorseListSource,
  HorseTrainerRef,
} from "../types";

/** Converte a violação do índice único do microchip em 'already-exists';
 * qualquer outro erro é relançado como está. Sempre lança.
 * @param {unknown} error Erro capturado na gravação.
 */
function rethrowDuplicateMicrochip(error: unknown): never {
  if (isDuplicateKeyError(error)) {
    throw new AppError("already-exists", "Microchip já cadastrado.");
  }
  throw error;
}

// Índices do DD em 'cavalos'.
const HORSE_INDEXES: IndexDescription[] = [
  {key: {codigo: 1}, name: "codigo_unico", unique: true},
  {key: {"proprietario._id": 1}, name: "idx_cavalos_proprietario"},
  {key: {"atleta._id": 1}, name: "idx_cavalos_atleta"},
  {key: {"treinadores._id": 1}, name: "idx_cavalos_treinadores"},
];

/** Garante os índices de 'cavalos'. Deve rodar fora da transação.
 * @return {Promise<void>} Resolvida quando os índices existirem.
 */
export const ensureHorseIndexes = (): Promise<void> =>
  ensureIndexesOnce(COLLECTIONS.Cavalos, HORSE_INDEXES);

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
    rethrowDuplicateMicrochip(error);
  }
}

/** Busca um cavalo ativo pelo _id.
 * @param {ObjectId} id _id do cavalo.
 * @param {ClientSession} session Sessão da transação, se houver.
 */
export async function findActiveHorseById(
  id: ObjectId,
  session?: ClientSession
): Promise<HorseDocument | null> {
  const db = await getDatabase();
  return db
    .collection<HorseDocument>(COLLECTIONS.Cavalos)
    .findOne({_id: id, situacaoCadastral: "ATIVO"}, {session});
}

/** Busca os cavalos ativos em que o responsável é proprietário ou atleta.
 * Usa idx_cavalos_proprietario e idx_cavalos_atleta.
 * @param {string} uid UID do responsável.
 */
export async function findGuardianListHorses(
  uid: string
): Promise<HorseListSource[]> {
  return findListHorses({
    "situacaoCadastral": "ATIVO",
    "$or": [{"proprietario._id": uid}, {"atleta._id": uid}],
  });
}

/** Busca os cavalos ativos acompanhados pelo treinador.
 * Usa idx_cavalos_treinadores.
 * @param {string} uid UID do treinador.
 */
export async function findTrainerListHorses(
  uid: string
): Promise<HorseListSource[]> {
  return findListHorses({
    "situacaoCadastral": "ATIVO",
    "treinadores._id": uid,
  });
}

/** Busca os _id dos cavalos ativos em que a pessoa é proprietária, atleta
 * ou treinadora, que são os vínculos que dão acesso aos exercícios do
 * cavalo. Usa idx_cavalos_proprietario, idx_cavalos_atleta e
 * idx_cavalos_treinadores.
 * @param {string} uid UID do responsável ou do treinador.
 * @return {Promise<ObjectId[]>} _id dos cavalos vinculados.
 */
export async function findLinkedHorseIds(uid: string): Promise<ObjectId[]> {
  const db = await getDatabase();
  const horses = await db
    .collection<HorseDocument>(COLLECTIONS.Cavalos)
    .find(
      {
        "situacaoCadastral": "ATIVO",
        "$or": [
          {"proprietario._id": uid},
          {"atleta._id": uid},
          {"treinadores._id": uid},
        ],
      },
      {projection: {_id: 1}}
    )
    .toArray();
  return horses.map((horse) => horse._id);
}

/** Lê os campos da lista, trazendo só a primeira imagem.
 * @param {Filter} filter Filtro dos cavalos.
 */
async function findListHorses(
  filter: Filter<HorseDocument>
): Promise<HorseListSource[]> {
  const db = await getDatabase();
  return db
    .collection<HorseDocument>(COLLECTIONS.Cavalos)
    .find(filter)
    .project<HorseListSource>({
      nome: 1,
      imagens: {$slice: 1},
      modalidade: 1,
      proprietario: 1,
      atleta: 1,
      treinadores: 1,
      criadoEm: 1,
    })
    .toArray();
}

/** Aplica a edição e devolve o documento atualizado; microchip repetido
 * vira 'already-exists'.
 * @param {ObjectId} id _id do cavalo.
 * @param {UpdateFilter} update Alterações ($set).
 * @param {ClientSession} session Sessão da transação.
 */
export async function updateHorseDocument(
  id: ObjectId,
  update: UpdateFilter<HorseDocument>,
  session: ClientSession
): Promise<HorseDocument | null> {
  const db = await getDatabase();
  try {
    return await db
      .collection<HorseDocument>(COLLECTIONS.Cavalos)
      .findOneAndUpdate(
        {_id: id, situacaoCadastral: "ATIVO"},
        update,
        {returnDocument: "after", session}
      );
  } catch (error) {
    rethrowDuplicateMicrochip(error);
  }
}

/** Acrescenta o caminho de uma imagem, respeitando o limite.
 * Devolve false se o limite foi atingido ou o caminho já estava gravado.
 * @param {ObjectId} id _id do cavalo.
 * @param {string} caminho Caminho da imagem no Storage.
 * @param {number} limit Máximo de imagens.
 */
export async function addHorseImage(
  id: ObjectId,
  caminho: string,
  limit: number
): Promise<boolean> {
  const db = await getDatabase();
  const result = await db
    .collection<HorseDocument>(COLLECTIONS.Cavalos)
    .updateOne(
      {
        _id: id,
        situacaoCadastral: "ATIVO",
        imagens: {$ne: caminho},
        [`imagens.${limit - 1}`]: {$exists: false},
      } as Filter<HorseDocument>,
      {
        $push: {imagens: caminho},
        $set: {atualizadoEm: new Date()},
      }
    );
  return result.modifiedCount === 1;
}

/** Remove a referência a uma imagem de um cavalo ativo.
 * @param {ObjectId} id _id do cavalo.
 * @param {string} caminho Caminho da imagem no Storage.
 */
export async function removeHorseImage(
  id: ObjectId,
  caminho: string
): Promise<boolean> {
  const db = await getDatabase();
  const result = await db
    .collection<HorseDocument>(COLLECTIONS.Cavalos)
    .updateOne(
      {_id: id, situacaoCadastral: "ATIVO", imagens: caminho},
      {$pull: {imagens: caminho}, $set: {atualizadoEm: new Date()}}
    );
  return result.modifiedCount === 1;
}

/** Lista os treinadores dos cavalos ativos, em ordem alfabética. Filtra
 * pela situação na coleção de origem: os _ids vêm de uma lista resumida.
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
      {$match: {_id: {$in: horseIds}, situacaoCadastral: "ATIVO"}},
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

/** Acrescenta um item a uma lista de saúde com $push, sem regravar a lista.
 * Lesões são mantidas em ordem decrescente de data.
 * @param {ObjectId} id _id do cavalo.
 * @param {HorseHealthEntryInput} entry Lista e item validados.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<HorseDocument|null>} Cavalo atualizado.
 */
export async function pushHealthEntry(
  id: ObjectId,
  entry: HorseHealthEntryInput,
  session: ClientSession
): Promise<HorseDocument | null> {
  const db = await getDatabase();
  const push = entry.lista === "historicoLesoes" ?
    {historicoLesoes: {$each: [entry.item], $sort: {data: -1}}} :
    {[entry.lista]: entry.item};
  return db
    .collection<HorseDocument>(COLLECTIONS.Cavalos)
    .findOneAndUpdate(
      {_id: id, situacaoCadastral: "ATIVO"},
      {
        $push: push as UpdateFilter<HorseDocument>["$push"],
        $set: {atualizadoEm: new Date()},
      },
      {returnDocument: "after", session}
    );
}

/** Exclusão lógica: o cavalo passa a INATIVO e o microchip continua
 * reservado pelo índice único.
 * @param {ObjectId} id _id do cavalo.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<boolean>} Se um cavalo ativo foi inativado.
 */
export async function deactivateHorse(
  id: ObjectId,
  session: ClientSession
): Promise<boolean> {
  const db = await getDatabase();
  const result = await db
    .collection<HorseDocument>(COLLECTIONS.Cavalos)
    .updateOne(
      {_id: id, situacaoCadastral: "ATIVO"},
      {$set: {situacaoCadastral: "INATIVO", atualizadoEm: new Date()}},
      {session}
    );
  return result.modifiedCount === 1;
}

/** Proprietários e atletas dos cavalos ativos do treinador, sem repetição.
 * Base do recálculo de treinadores.clientes. Usa idx_cavalos_treinadores.
 * @param {string} trainerId UID do treinador.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<AccountRef[]>} Clientes derivados dos cavalos.
 */
export async function findClientsFromHorses(
  trainerId: string,
  session: ClientSession
): Promise<AccountRef[]> {
  const db = await getDatabase();
  const horses = await db
    .collection<HorseDocument>(COLLECTIONS.Cavalos)
    .find(
      {"treinadores._id": trainerId, "situacaoCadastral": "ATIVO"},
      {projection: {proprietario: 1, atleta: 1}, session}
    )
    .toArray();

  const clients = new Map<string, AccountRef>();
  for (const horse of horses) {
    for (const person of [horse.proprietario, horse.atleta]) {
      if (person && !clients.has(person._id)) {
        clients.set(person._id, {
          _id: person._id,
          codigo: person.codigo,
          nome: person.nome,
        });
      }
    }
  }
  return [...clients.values()];
}
