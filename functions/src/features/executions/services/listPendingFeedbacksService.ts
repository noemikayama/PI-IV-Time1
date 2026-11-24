// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Execuções dos planos do treinador que esperam feedback.
// -----------------------------------------------------------------------------

import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import {toYmd} from "../../../shared/utils/dates";
import {assertActiveAccount} from "../../horses";
import {
  ensureTrainingRecordIndexes,
  findPendingFeedbackRecords,
} from "../../training";
import {PENDING_FEEDBACKS_LIMIT} from "../constants/limits";
import type {PendingFeedbackList} from "../types";

/** Lista as execuções dos planos do treinador que ainda esperam feedback,
 * da mais recente para a mais antiga. Inclui cavalos excluídos e planos
 * encerrados, porque o treinador do plano ainda pode responder. Lê um item
 * a mais para saber se há outros além do limite.
 * @param {AuthenticatedUser} user Treinador autenticado.
 * @return {Promise<PendingFeedbackList>} Execuções e se há mais.
 */
export async function listPendingFeedbacksService(
  user: AuthenticatedUser
): Promise<PendingFeedbackList> {
  await Promise.all([
    assertActiveAccount(user.uid, user.role),
    ensureTrainingRecordIndexes(),
  ]);
  const records = await findPendingFeedbackRecords(
    user.uid,
    PENDING_FEEDBACKS_LIMIT + 1
  );
  return {
    execucoes: records.slice(0, PENDING_FEEDBACKS_LIMIT).map((record) => ({
      id: record._id.toHexString(),
      data: record.dataExecucao ? toYmd(record.dataExecucao) : null,
      status: record.status,
      duracaoEfetiva: record.duracaoEfetivaMinutos ?? null,
      nomeTreinamento: record.treinamento.titulo,
      nomeCavalo: record.cavalo.nome,
      nomeAtleta: record.responsavel?.nome ?? null,
    })),
    possuiMais: records.length > PENDING_FEEDBACKS_LIMIT,
  };
}
