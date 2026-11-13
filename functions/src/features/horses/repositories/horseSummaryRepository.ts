// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Microchip e nome também em exercicios.cavalo (antes feito
// pelo renameHorseRefs da developer, só com o nome).
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cópias do cavalo fora da coleção 'cavalos', reunidas a partir
// de horseRepository.ts e horseLinkRepository.ts (este último removido).
// -----------------------------------------------------------------------------

// Cópias do cavalo em outras coleções (DD 5.2, "Manutenção das listas
// resumidas e cópias"): responsaveis.cavalos, treinadores.cavalos,
// treinadores.clientes e o campo 'cavalo' de avaliacoes, planos,
// registros_treino e exercicios. A fonte da verdade é a coleção 'cavalos'
// (horseRepository.ts). Todas as funções rodam em transação, em operações
// sequenciais: a mesma sessão não deve executar comandos em paralelo.
import type {ClientSession, Document, ObjectId} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import type {GuardianDocument} from "../../authentication/guardian/types";
import type {TrainerDocument} from "../../authentication/trainer/types";
import type {
  AccountRef,
  HorseDocument,
  HorseResponsibility,
  TrainerHorseRef,
} from "../types";

// Trechos dos documentos de authentication que esta feature mantém.
type GuardianHorses = Pick<
  GuardianDocument,
  "_id" | "situacaoCadastral" | "cavalos" | "atualizadoEm"
>;
type TrainerLinks = Pick<
  TrainerDocument,
  "_id" | "cavalos" | "clientes" | "atualizadoEm"
>;

// Só para o $pull com condição ($size) em removeGuardianResponsibility: o
// driver não tipa condição de query dentro do $pull.
type GuardianHorseDocs = {_id: string; cavalos: Document[]; atualizadoEm: Date};

// ---------------------------------------------------------------------------
// responsaveis.cavalos
// ---------------------------------------------------------------------------

/** Acrescenta responsabilidades ao item do cavalo em responsaveis.cavalos.
 * Se o item já existe (ex.: o proprietário passa a ser também atleta), só
 * as responsabilidades novas entram; senão, o item é criado, desde que o
 * responsável esteja ATIVO. Usada no cadastro e na troca de atleta.
 * @param {string} uid UID do responsável.
 * @param {TrainerHorseRef} horse _id, microchip e nome do cavalo.
 * @param {HorseResponsibility[]} responsabilidades Responsabilidades.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<boolean>} false se o responsável não existe ou está
 * inativo; quem chama decide o erro e, ao lançá-lo, aborta a transação.
 */
export async function addHorseToGuardian(
  uid: string,
  horse: TrainerHorseRef,
  responsabilidades: HorseResponsibility[],
  session: ClientSession
): Promise<boolean> {
  const db = await getDatabase();
  const guardians = db.collection<GuardianHorses>(COLLECTIONS.Responsaveis);
  const atualizadoEm = new Date();

  const existing = await guardians.updateOne(
    {"_id": uid, "cavalos._id": horse._id},
    {
      $addToSet: {"cavalos.$.responsabilidades": {$each: responsabilidades}},
      $set: {atualizadoEm},
    },
    {session}
  );
  if (existing.matchedCount === 1) return true;

  const created = await guardians.updateOne(
    {"_id": uid, "situacaoCadastral": "ATIVO", "cavalos._id": {$ne: horse._id}},
    {
      $push: {cavalos: {...horse, responsabilidades}},
      $set: {atualizadoEm},
    },
    {session}
  );
  return created.matchedCount === 1;
}

/** Retira uma responsabilidade do item do cavalo em responsaveis.cavalos e
 * remove o item se não sobrar nenhuma.
 * @param {string} uid UID do responsável.
 * @param {ObjectId} horseId _id do cavalo.
 * @param {HorseResponsibility} responsabilidade Responsabilidade retirada.
 * @param {ClientSession} session Sessão da transação.
 */
export async function removeGuardianResponsibility(
  uid: string,
  horseId: ObjectId,
  responsabilidade: HorseResponsibility,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  const atualizadoEm = new Date();

  await db.collection<GuardianHorses>(COLLECTIONS.Responsaveis).updateOne(
    {"_id": uid, "cavalos._id": horseId},
    {
      $pull: {"cavalos.$.responsabilidades": responsabilidade},
      $set: {atualizadoEm},
    },
    {session}
  );
  await db.collection<GuardianHorseDocs>(COLLECTIONS.Responsaveis).updateOne(
    {_id: uid},
    {
      $pull: {cavalos: {_id: horseId, responsabilidades: {$size: 0}}},
      $set: {atualizadoEm},
    },
    {session}
  );
}

/** Remove o item do cavalo de responsaveis.cavalos (exclusão do cavalo).
 * @param {string} uid UID do responsável.
 * @param {ObjectId} horseId _id do cavalo.
 * @param {ClientSession} session Sessão da transação.
 */
export async function removeHorseFromGuardian(
  uid: string,
  horseId: ObjectId,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  await db.collection<GuardianHorses>(COLLECTIONS.Responsaveis).updateOne(
    {"_id": uid, "cavalos._id": horseId},
    {$pull: {cavalos: {_id: horseId}}, $set: {atualizadoEm: new Date()}},
    {session}
  );
}

// ---------------------------------------------------------------------------
// treinadores.cavalos e treinadores.clientes
// ---------------------------------------------------------------------------

/** Acrescenta o cavalo em treinadores.cavalos, se ainda não estiver lá.
 * @param {string} trainerId UID do treinador.
 * @param {TrainerHorseRef} horse _id, microchip e nome do cavalo.
 * @param {ClientSession} session Sessão da transação.
 */
export async function addHorseToTrainer(
  trainerId: string,
  horse: TrainerHorseRef,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  await db.collection<TrainerLinks>(COLLECTIONS.Treinadores).updateOne(
    {"_id": trainerId, "cavalos._id": {$ne: horse._id}},
    {$push: {cavalos: horse}, $set: {atualizadoEm: new Date()}},
    {session}
  );
}

/** Remove o cavalo de treinadores.cavalos.
 * @param {string} trainerId UID do treinador.
 * @param {ObjectId} horseId _id do cavalo.
 * @param {ClientSession} session Sessão da transação.
 */
export async function removeHorseFromTrainer(
  trainerId: string,
  horseId: ObjectId,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  await db.collection<TrainerLinks>(COLLECTIONS.Treinadores).updateOne(
    {"_id": trainerId, "cavalos._id": horseId},
    {$pull: {cavalos: {_id: horseId}}, $set: {atualizadoEm: new Date()}},
    {session}
  );
}

/** Lê a lista de clientes gravada no treinador.
 * @param {string} trainerId UID do treinador.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<AccountRef[]|null>} Clientes, ou null sem treinador.
 */
export async function findTrainerClients(
  trainerId: string,
  session: ClientSession
): Promise<AccountRef[] | null> {
  const db = await getDatabase();
  const trainer = await db
    .collection<TrainerLinks>(COLLECTIONS.Treinadores)
    .findOne({_id: trainerId}, {projection: {clientes: 1}, session});
  return trainer ? trainer.clientes ?? [] : null;
}

/** Grava a lista de clientes do treinador.
 * @param {string} trainerId UID do treinador.
 * @param {AccountRef[]} clientes Lista final.
 * @param {ClientSession} session Sessão da transação.
 */
export async function setTrainerClients(
  trainerId: string,
  clientes: AccountRef[],
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  await db.collection<TrainerLinks>(COLLECTIONS.Treinadores).updateOne(
    {_id: trainerId},
    {$set: {clientes, atualizadoEm: new Date()}},
    {session}
  );
}

// ---------------------------------------------------------------------------
// Microchip e nome em todas as cópias
// ---------------------------------------------------------------------------

/** Atualiza o microchip e o nome do cavalo nas cópias resumidas:
 * responsaveis.cavalos, treinadores.cavalos e o campo 'cavalo' de
 * avaliacoes, planos, registros_treino e exercicios. Só altera as cópias
 * diferentes, então pode ser chamada sempre.
 * @param {ObjectId} id _id do cavalo.
 * @param {Pick<HorseDocument, "codigo" | "nome">} ref Valores atuais.
 * @param {ClientSession} session Sessão da transação.
 */
export async function syncHorseRefs(
  id: ObjectId,
  ref: Pick<HorseDocument, "codigo" | "nome">,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  const {codigo, nome} = ref;
  const outdated = [{codigo: {$ne: codigo}}, {nome: {$ne: nome}}];
  const atualizadoEm = new Date();

  const summaries = [COLLECTIONS.Responsaveis, COLLECTIONS.Treinadores];
  for (const collection of summaries) {
    await db.collection(collection).updateMany(
      {cavalos: {$elemMatch: {_id: id, $or: outdated}}},
      {
        $set: {
          "cavalos.$[cavalo].codigo": codigo,
          "cavalos.$[cavalo].nome": nome,
          atualizadoEm,
        },
      },
      {arrayFilters: [{"cavalo._id": id}], session}
    );
  }

  const copies = [
    COLLECTIONS.Avaliacoes,
    COLLECTIONS.Planos,
    COLLECTIONS.RegistrosTreino,
    COLLECTIONS.Exercicios,
  ];
  for (const collection of copies) {
    await db.collection(collection).updateMany(
      {
        "cavalo._id": id,
        "$or": [
          {"cavalo.codigo": {$ne: codigo}},
          {"cavalo.nome": {$ne: nome}},
        ],
      },
      {$set: {"cavalo.codigo": codigo, "cavalo.nome": nome}},
      {session}
    );
  }
}
