// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
  ExerciseMediaField,
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
