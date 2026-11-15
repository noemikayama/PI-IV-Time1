// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Gravação da avaliação e do resumo em cavalos.avaliacoes.
// Alteração: Índice criado pelo helper compartilhado ensureIndexesOnce.
// -----------------------------------------------------------------------------

// Coleção 'avaliacoes' e a parte de 'cavalos' que esta feature mantém
// (avaliacoes, o histórico resumido). Índice do DD: idx_avaliacoes_cavalo_data.
import type {ClientSession, ObjectId} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import {ensureIndexesOnce} from "../../../shared/database/indexes";
import {nextCode} from "../../../shared/database/sequence";
import {AppError} from "../../../shared/errors/AppError";
import type {HorseDocument} from "../../horses";
import type {
  EvaluationDocument,
  EvaluationSummary,
  NewEvaluation,
} from "../types";

/** Garante o índice do histórico por cavalo. Deve rodar fora da transação.
 * @return {Promise<void>} Resolvida quando o índice existir.
 */
export const ensureEvaluationIndexes = (): Promise<void> =>
  ensureIndexesOnce(COLLECTIONS.Avaliacoes, [
    {key: {"cavalo._id": 1, "data": -1}, name: "idx_avaliacoes_cavalo_data"},
  ]);

/** Grava a avaliação com o próximo código sequencial.
 * @param {NewEvaluation} evaluation Avaliação sem o código.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<EvaluationDocument>} Avaliação gravada.
 */
export async function insertEvaluation(
  evaluation: NewEvaluation,
  session: ClientSession
): Promise<EvaluationDocument> {
  const db = await getDatabase();
  const codigo = await nextCode(COLLECTIONS.Avaliacoes, session);
  const document: EvaluationDocument = {...evaluation, codigo};
  await db
    .collection<EvaluationDocument>(COLLECTIONS.Avaliacoes)
    .insertOne(document, {session});
  return document;
}

/** Insere o resumo em cavalos.avaliacoes, mantendo a ordem decrescente de
 * data (DD 5.2). Lançar aqui aborta a transação e desfaz a avaliação.
 * @param {ObjectId} horseId _id do cavalo.
 * @param {EvaluationSummary} summary Resumo da avaliação.
 * @param {ClientSession} session Sessão da transação.
 */
export async function addEvaluationToHorse(
  horseId: ObjectId,
  summary: EvaluationSummary,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  const result = await db
    .collection<HorseDocument>(COLLECTIONS.Cavalos)
    .updateOne(
      {_id: horseId, situacaoCadastral: "ATIVO"},
      {
        $push: {
          avaliacoes: {$each: [summary], $sort: {data: -1, codigo: -1}},
        },
        $set: {atualizadoEm: new Date()},
      },
      {session}
    );
  if (result.matchedCount === 0) {
    throw new AppError("not-found", "Cavalo não encontrado.");
  }
}
