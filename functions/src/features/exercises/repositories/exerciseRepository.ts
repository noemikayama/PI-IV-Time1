// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Leitura do código e dos materiais dos exercícios ativos
// (findActiveExerciseExtras), usada pelo treino agendado.
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Consulta do exercício ativo pelo código (detalhes do
// exercício) e gravação da edição pelo autor.
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consultas por código do treinador e do tipo e cavalo dos
// exercícios, usadas pela edição e pelos detalhes do treinamento.
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exercícios específicos de outro cavalo, usados pelo plano.
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consultas da galeria e dos exercícios do treinador por _id,
// usadas pelo cadastro de treinamentos.
//
// Data: 07/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Índices, inserção (com geração do código sequencial), consulta
// por _id e inclusão e remoção de mídias do exercício.
//
// Data: 30/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Período opcional de cadastro, usado pelo dashboard.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Contagem de exercícios ativos do treinador para a home.
// -----------------------------------------------------------------------------

// Coleção 'exercicios'. Índices do DD: idx_exercicios_treinador e
// idx_exercicios_nome, além do único em 'codigo'.
import type {
  ClientSession,
  Filter,
  ObjectId,
  UpdateFilter,
} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import {nextCode} from "../../../shared/database/sequence";
import {inPeriod} from "../../../shared/utils/dates";
import type {DatePeriod} from "../../../shared/utils/dates";
import type {
  ExerciseDocument,
  ExerciseExtrasSource,
  ExerciseGallerySource,
  ExerciseKindSource,
  ExerciseMediaField,
  ExercisePrivacy,
  NewExercise,
} from "../types";

// Criado uma vez por processo; createIndexes não altera um índice existente.
let indexesReady: Promise<void> | undefined;

/** Garante os índices da coleção. Deve rodar fora da transação.
 * @return {Promise<void>} Resolvida quando os índices existirem.
 */
export function ensureExerciseIndexes(): Promise<void> {
  if (!indexesReady) {
    indexesReady = getDatabase()
      .then((db) =>
        db.collection(COLLECTIONS.Exercicios).createIndexes([
          {key: {codigo: 1}, name: "codigo_unico", unique: true},
          {key: {"treinador._id": 1}, name: "idx_exercicios_treinador"},
          {
            key: {nome: "text"},
            name: "idx_exercicios_nome",
            default_language: "portuguese",
          },
        ])
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

/** Grava o exercício e devolve o código sequencial atribuído.
 * @param {NewExercise} exercise Dados do exercício.
 * @param {ClientSession} session Sessão da transação.
 */
export async function insertExercise(
  exercise: NewExercise,
  session: ClientSession
): Promise<number> {
  const db = await getDatabase();
  const codigo = await nextCode(COLLECTIONS.Exercicios, session);

  await db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .insertOne({...exercise, codigo}, {session});

  return codigo;
}

/** Busca um exercício ativo pelo _id.
 * @param {ObjectId} id _id do exercício.
 */
export async function findActiveExerciseById(
  id: ObjectId
): Promise<ExerciseDocument | null> {
  const db = await getDatabase();
  return db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .findOne({_id: id, ativo: true});
}

/** Busca um exercício ativo pelo código sequencial. Usa o índice único de
 * 'codigo'.
 * @param {number} codigo Código do exercício.
 * @return {Promise<ExerciseDocument|null>} Exercício, ou null.
 */
export async function findActiveExerciseByCode(
  codigo: number
): Promise<ExerciseDocument | null> {
  const db = await getDatabase();
  return db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .findOne({codigo, ativo: true});
}

/** Aplica a edição se o exercício estiver ativo e for do treinador
 * informado, e devolve o documento já atualizado. O filtro pelo autor
 * repete a conferência do service, como defesa extra.
 * @param {ObjectId} id _id do exercício.
 * @param {string} trainerId UID do treinador que edita.
 * @param {UpdateFilter<ExerciseDocument>} update Alterações ($set e $unset).
 * @return {Promise<ExerciseDocument|null>} Exercício atualizado, ou null.
 */
export async function updateAuthorExercise(
  id: ObjectId,
  trainerId: string,
  update: UpdateFilter<ExerciseDocument>
): Promise<ExerciseDocument | null> {
  const db = await getDatabase();
  return db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .findOneAndUpdate(
      {"_id": id, "ativo": true, "treinador._id": trainerId},
      update,
      {returnDocument: "after"}
    );
}

/** Acrescenta o caminho de uma mídia, respeitando o limite do campo.
 * Devolve false se o limite foi atingido ou o caminho já estava gravado.
 * @param {ObjectId} id _id do exercício.
 * @param {ExerciseMediaField} field Campo da mídia (imagens ou videos).
 * @param {string} caminho Caminho da mídia no Storage.
 * @param {number} limit Máximo de arquivos no campo.
 */
export async function addExerciseMedia(
  id: ObjectId,
  field: ExerciseMediaField,
  caminho: string,
  limit: number
): Promise<boolean> {
  const db = await getDatabase();
  const result = await db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .updateOne(
      {
        _id: id,
        ativo: true,
        [field]: {$ne: caminho},
        [`${field}.${limit - 1}`]: {$exists: false},
      } as Filter<ExerciseDocument>,
      {
        $push: {[field]: caminho},
        $set: {atualizadoEm: new Date()},
      } as UpdateFilter<ExerciseDocument>
    );
  return result.modifiedCount === 1;
}

/** Remove a referência a uma mídia.
 * @param {ObjectId} id _id do exercício.
 * @param {ExerciseMediaField} field Campo da mídia (imagens ou videos).
 * @param {string} caminho Caminho da mídia no Storage.
 */
export async function removeExerciseMedia(
  id: ObjectId,
  field: ExerciseMediaField,
  caminho: string
): Promise<boolean> {
  const db = await getDatabase();
  const result = await db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .updateOne(
      {_id: id, [field]: caminho} as Filter<ExerciseDocument>,
      {
        $pull: {[field]: caminho},
        $set: {atualizadoEm: new Date()},
      } as UpdateFilter<ExerciseDocument>
    );
  return result.modifiedCount === 1;
}

// Usa idx_exercicios_treinador. Exercícios removidos (ativo = false) não
// contam, nem os da plataforma, que não têm treinador.
/** Conta os exercícios ativos cadastrados pelo treinador.
 * @param {string} trainerId UID do treinador.
 * @param {DatePeriod} createdIn Período de 'criadoEm' ou null (todos).
 */
export async function countActiveExercisesByTrainer(
  trainerId: string,
  createdIn: DatePeriod | null = null
): Promise<number> {
  const db = await getDatabase();
  return db
    .collection(COLLECTIONS.Exercicios)
    .countDocuments({
      "treinador._id": trainerId,
      "ativo": true,
      ...(createdIn ? inPeriod("criadoEm", createdIn) : {}),
    });
}

/** Busca os exercícios ativos do treinador para a galeria: os genéricos
 * (horseId null) ou os específicos do cavalo informado. Usa
 * idx_exercicios_treinador.
 * @param {string} trainerId UID do treinador.
 * @param {ExercisePrivacy} privacidade GENERICO ou ESPECIFICO.
 * @param {ObjectId|null} horseId _id do cavalo, no ESPECIFICO.
 */
export async function findGalleryExercises(
  trainerId: string,
  privacidade: ExercisePrivacy,
  horseId: ObjectId | null
): Promise<ExerciseGallerySource[]> {
  const db = await getDatabase();
  return db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .find({
      "treinador._id": trainerId,
      "ativo": true,
      privacidade,
      ...(horseId && {"cavalo._id": horseId}),
    })
    .project<ExerciseGallerySource>({
      nome: 1,
      duracaoPadraoMinutos: 1,
      privacidade: 1,
      cavalo: 1,
    })
    .toArray();
}

/** Busca, entre os _id informados, os exercícios ativos cadastrados pelo
 * treinador. Os que não existem, foram excluídos ou são de outro dono não
 * voltam. Usa o índice de _id.
 * @param {string} trainerId UID do treinador.
 * @param {ObjectId[]} ids _id dos exercícios, sem repetição.
 */
export async function findTrainerExercisesByIds(
  trainerId: string,
  ids: ObjectId[]
): Promise<ExerciseDocument[]> {
  const db = await getDatabase();
  return db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .find({"_id": {$in: ids}, "treinador._id": trainerId, "ativo": true})
    .toArray();
}

/** Busca, entre os códigos informados, os exercícios ativos cadastrados
 * pelo treinador. Os que não existem, foram excluídos ou são de outro dono
 * não voltam. Usa o índice único de 'codigo'.
 * @param {string} trainerId UID do treinador.
 * @param {number[]} codes Códigos dos exercícios, sem repetição.
 */
export async function findTrainerExercisesByCodes(
  trainerId: string,
  codes: number[]
): Promise<ExerciseDocument[]> {
  if (codes.length === 0) return [];
  const db = await getDatabase();
  return db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .find({"codigo": {$in: codes}, "treinador._id": trainerId, "ativo": true})
    .toArray();
}

/** Lê o tipo (privacidade) e o cavalo dos exercícios, inclusive os
 * inativos, porque a cópia no treinamento continua valendo. Consulta direta
 * por _id.
 * @param {ObjectId[]} ids _id dos exercícios (cópias dos treinamentos).
 */
export async function findExerciseKinds(
  ids: ObjectId[]
): Promise<ExerciseKindSource[]> {
  if (ids.length === 0) return [];
  const db = await getDatabase();
  return db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .find({_id: {$in: ids}})
    .project<ExerciseKindSource>({privacidade: 1, cavalo: 1})
    .toArray();
}

/** Dos exercícios informados, devolve os _id dos específicos de um cavalo
 * diferente do informado (inclusive os inativos, porque a cópia no
 * treinamento continua valendo). Consulta direta por _id.
 * @param {ObjectId[]} ids _id dos exercícios (cópias dos treinamentos).
 * @param {ObjectId} horseId _id do cavalo do plano.
 * @return {Promise<ObjectId[]>} _id dos exercícios de outro cavalo.
 */
export async function findForeignSpecificExerciseIds(
  ids: ObjectId[],
  horseId: ObjectId
): Promise<ObjectId[]> {
  if (ids.length === 0) return [];
  const db = await getDatabase();
  const found = await db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .find(
      {
        "_id": {$in: ids},
        "privacidade": "ESPECIFICO",
        "cavalo._id": {$ne: horseId},
      },
      {projection: {_id: 1}}
    )
    .toArray();
  return found.map((exercise) => exercise._id);
}

/** Lê código e materiais dos exercícios ativos informados, para o treino
 * agendado (a cópia no treino não guarda materiais, e o código localiza as
 * mídias no Storage). Consulta direta por _id. Exercício inativo ou
 * inexistente não volta.
 * @param {ObjectId[]} ids _id dos exercícios, sem repetição.
 * @return {Promise<ExerciseExtrasSource[]>} Exercícios encontrados.
 */
export async function findActiveExerciseExtras(
  ids: ObjectId[]
): Promise<ExerciseExtrasSource[]> {
  if (ids.length === 0) return [];
  const db = await getDatabase();
  return db
    .collection<ExerciseDocument>(COLLECTIONS.Exercicios)
    .find({_id: {$in: ids}, ativo: true})
    .project<ExerciseExtrasSource>({codigo: 1, materiais: 1})
    .toArray();
}
