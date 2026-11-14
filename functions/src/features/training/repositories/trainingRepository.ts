// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Índices e inserção de treinamentos (com geração do código
// sequencial).
// -----------------------------------------------------------------------------

// Coleção 'treinamentos'. Índices do DD: idx_treinamentos_treinador e
// idx_treinamentos_titulo, além do único em 'codigo'.
import type {ClientSession, IndexDescription} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import {ensureIndexesOnce} from "../../../shared/database/indexes";
import {nextCode} from "../../../shared/database/sequence";
import type {NewTraining, TrainingDocument} from "../types";

const TRAINING_INDEXES: IndexDescription[] = [
  {key: {codigo: 1}, name: "codigo_unico", unique: true},
  {key: {"treinador._id": 1}, name: "idx_treinamentos_treinador"},
  {
    key: {titulo: "text"},
    name: "idx_treinamentos_titulo",
    default_language: "portuguese",
  },
];

/** Garante os índices de 'treinamentos'. Deve rodar fora da transação.
 * @return {Promise<void>} Resolvida quando os índices existirem.
 */
export const ensureTrainingIndexes = (): Promise<void> =>
  ensureIndexesOnce(COLLECTIONS.Treinamentos, TRAINING_INDEXES);

/** Grava o treinamento e devolve o código sequencial atribuído.
 * @param {NewTraining} training Dados do treinamento.
 * @param {ClientSession} session Sessão da transação.
 */
export async function insertTraining(
  training: NewTraining,
  session: ClientSession
): Promise<number> {
  const db = await getDatabase();
  const codigo = await nextCode(COLLECTIONS.Treinamentos, session);

  await db
    .collection<TrainingDocument>(COLLECTIONS.Treinamentos)
    .insertOne({...training, codigo}, {session});

  return codigo;
}
