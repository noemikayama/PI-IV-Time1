// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Atualização do nome do treinador também em
// exercicios.treinador.
// Alteração: Gravação da situação profissional na edição do perfil.
//
// Data: 29/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Edição do perfil do treinador e atualização das cópias do nome.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Gravação e remoção dos caminhos dos anexos em PDF.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Padronização do formato da consulta da home.
//
// Data: 14/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Obtenção de dados da home.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Gravação do perfil do treinador e geração do código.
// -----------------------------------------------------------------------------

// Coleção 'treinadores'.
// O _id (UID do Firebase) já é único; não há índices extras.
import type {ClientSession, Filter, UpdateFilter} from "mongodb";
import {getDatabase} from "../../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../../shared/constants/collections";
import {nextCode} from "../../../../shared/database/sequence";
import type {
  AttachmentType,
  NewTrainer,
  TrainerDocument,
  TrainerHomeSource,
  TrainerProfileChanges,
} from "../types";

/** Grava o treinador e devolve o código sequencial atribuído.
 * @param {NewTrainer} trainer Dados do treinador.
 * @param {ClientSession} session Sessão da transação.
 */
export async function insertTrainer(
  trainer: NewTrainer,
  session: ClientSession
): Promise<number> {
  const db = await getDatabase();
  const codigo = await nextCode(COLLECTIONS.Treinadores, session);

  await db
    .collection<TrainerDocument>(COLLECTIONS.Treinadores)
    .insertOne({...trainer, codigo}, {session});

  return codigo;
}

/** Busca o cadastro do treinador pelo UID do Firebase.
 * @param {string} uid UID do usuário.
 * @param {ClientSession} session Sessão da transação, se houver.
 */
export async function findTrainerById(
  uid: string,
  session?: ClientSession
): Promise<TrainerDocument | null> {
  const db = await getDatabase();
  return db
    .collection<TrainerDocument>(COLLECTIONS.Treinadores)
    .findOne({_id: uid}, {session});
}

/** Busca os dados mínimos do treinador usados pela home.
 * @param {string} uid UID do usuário.
 */
export async function findTrainerHomeSource(
  uid: string
): Promise<TrainerHomeSource | null> {
  const db = await getDatabase();
  return db
    .collection<TrainerDocument>(COLLECTIONS.Treinadores)
    .findOne<TrainerHomeSource>(
      {_id: uid},
      {
        projection: {
          nome: 1,
          situacaoProfissional: 1,
          cavalos: 1,
          clientes: 1,
        },
      }
    );
}

/** Grava o caminho do PDF de experiências (substitui o anterior).
 * @param {string} uid UID do usuário.
 * @param {string} caminho Caminho do arquivo no Storage.
 */
export async function setTrainerExperience(
  uid: string,
  caminho: string
): Promise<boolean> {
  const db = await getDatabase();
  const result = await db
    .collection<TrainerDocument>(COLLECTIONS.Treinadores)
    .updateOne(
      {_id: uid},
      {$set: {experiencias: caminho, atualizadoEm: new Date()}}
    );
  return result.matchedCount === 1;
}

/** Acrescenta o caminho de uma certificação, respeitando o limite.
 * Devolve false se o limite foi atingido ou o caminho já estava gravado.
 * @param {string} uid UID do usuário.
 * @param {string} caminho Caminho do arquivo no Storage.
 * @param {number} limit Máximo de certificações.
 */
export async function addTrainerCertification(
  uid: string,
  caminho: string,
  limit: number
): Promise<boolean> {
  const db = await getDatabase();
  const result = await db
    .collection<TrainerDocument>(COLLECTIONS.Treinadores)
    .updateOne(
      {
        _id: uid,
        certificacoes: {$ne: caminho},
        [`certificacoes.${limit - 1}`]: {$exists: false},
      } as Filter<TrainerDocument>,
      {
        $push: {certificacoes: caminho},
        $set: {atualizadoEm: new Date()},
      }
    );
  return result.modifiedCount === 1;
}

/** Remove a referência a um PDF (experiência vira null).
 * @param {string} uid UID do usuário.
 * @param {AttachmentType} tipo Tipo do anexo.
 * @param {string} caminho Caminho do arquivo no Storage.
 */
export async function removeTrainerFile(
  uid: string,
  tipo: AttachmentType,
  caminho: string
): Promise<boolean> {
  const db = await getDatabase();
  const collection = db.collection<TrainerDocument>(
    COLLECTIONS.Treinadores
  );
  const now = new Date();
  const result = tipo === "experiencias" ?
    await collection.updateOne(
      {_id: uid, experiencias: caminho},
      {$set: {experiencias: null, atualizadoEm: now}}
    ) :
    await collection.updateOne(
      {_id: uid},
      {$pull: {certificacoes: caminho}, $set: {atualizadoEm: now}}
    );
  return result.modifiedCount === 1;
}

/** Aplica as alterações do perfil ao treinador ativo.
 * Só os campos presentes em 'changes' são alterados, além de 'atualizadoEm'.
 * @param {string} uid UID do usuário.
 * @param {TrainerProfileChanges} changes Alterações já conferidas.
 * @param {Date} atualizadoEm Data da alteração.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<TrainerDocument|null>} Perfil atualizado.
 */
export async function updateTrainerProfileDocument(
  uid: string,
  changes: TrainerProfileChanges,
  atualizadoEm: Date,
  session: ClientSession
): Promise<TrainerDocument | null> {
  const db = await getDatabase();
  const update: UpdateFilter<TrainerDocument> = {$set: {atualizadoEm}};

  if (changes.nome !== undefined) {
    update.$set = {...update.$set, nome: changes.nome};
  }
  if (changes.situacaoProfissional !== undefined) {
    update.$set = {
      ...update.$set,
      situacaoProfissional: changes.situacaoProfissional,
    };
  }
  if (changes.regioesAtendimento) {
    update.$set = {
      ...update.$set,
      regioesAtendimento: changes.regioesAtendimento,
    };
  }
  if (changes.removerExperiencia !== undefined) {
    update.$set = {...update.$set, experiencias: null};
  }
  if (changes.removerCertificacoes.length > 0) {
    update.$pull = {certificacoes: {$in: changes.removerCertificacoes}};
  }

  return db
    .collection<TrainerDocument>(COLLECTIONS.Treinadores)
    .findOneAndUpdate(
      {_id: uid, situacaoProfissional: {$ne: "INATIVO"}},
      update,
      {returnDocument: "after", session}
    );
}

/** Atualiza o nome do treinador nas cópias de cavalos, registros de treino e
 * exercícios.
 * Só altera as cópias com nome diferente, então pode ser chamada sempre.
 * @param {string} uid UID do treinador.
 * @param {string} nome Novo nome.
 * @param {ClientSession} session Sessão da transação.
 */
export async function renameTrainerRefs(
  uid: string,
  nome: string,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  const atualizadoEm = new Date();
  const horses = db.collection(COLLECTIONS.Cavalos);

  // As operações são sequenciais: a mesma sessão não deve executar comandos
  // em paralelo. cavalos.treinadores e cavalos.avaliacoes.treinador ficam em
  // operações separadas porque o filtro de array exige que o campo exista.
  await horses.updateMany(
    {treinadores: {$elemMatch: {_id: uid, nome: {$ne: nome}}}},
    {$set: {"treinadores.$[treinador].nome": nome, atualizadoEm}},
    {arrayFilters: [{"treinador._id": uid}], session}
  );
  await horses.updateMany(
    {
      avaliacoes: {
        $elemMatch: {"treinador._id": uid, "treinador.nome": {$ne: nome}},
      },
    },
    {$set: {"avaliacoes.$[avaliacao].treinador.nome": nome, atualizadoEm}},
    {arrayFilters: [{"avaliacao.treinador._id": uid}], session}
  );
  await db.collection(COLLECTIONS.RegistrosTreino).updateMany(
    {"treinador._id": uid, "treinador.nome": {$ne: nome}},
    {$set: {"treinador.nome": nome}},
    {session}
  );
  // Usa idx_exercicios_treinador. O atualizadoEm do exercício não muda: o
  // conteúdo dele continua o mesmo.
  await db.collection(COLLECTIONS.Exercicios).updateMany(
    {"treinador._id": uid, "treinador.nome": {$ne: nome}},
    {$set: {"treinador.nome": nome}},
    {session}
  );
}
