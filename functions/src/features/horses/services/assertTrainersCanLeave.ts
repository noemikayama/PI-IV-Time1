// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta do autor do plano ativo importada da feature de
// planos.
//
// Data: 04/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Regra do autor do plano ativo (RF05003), antes em
// updateHorseLinksService.ts, compartilhada com o desvínculo.
// -----------------------------------------------------------------------------

import type {ClientSession, ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {isActivePlanAuthor} from "../../plans";
import type {AccountRef} from "../types";

/** Recusa a saída de um treinador que seja autor do plano ATIVO do cavalo
 * (RF05003). Usada na troca e no desvínculo do treinador.
 * @param {ObjectId} horseId _id do cavalo.
 * @param {AccountRef[]} leaving Treinadores que deixam o cavalo.
 * @param {ClientSession} session Sessão da transação.
 */
export async function assertTrainersCanLeave(
  horseId: ObjectId,
  leaving: AccountRef[],
  session: ClientSession
): Promise<void> {
  for (const trainer of leaving) {
    if (await isActivePlanAuthor(horseId, trainer._id, session)) {
      throw new AppError(
        "failed-precondition",
        `${trainer.nome} é autor do plano ativo do cavalo e não pode ser ` +
          "desvinculado."
      );
    }
  }
}
