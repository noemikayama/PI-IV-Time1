// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Acesso ao treino agendado, com a regra da visualização do
// plano.
// -----------------------------------------------------------------------------

import type {ClientSession} from "mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import {findActiveHorseById, relationsOf} from "../../horses";
import type {TrainingRecordDocument} from "../../training";
import type {RecordViewer} from "../types";

export const RECORD_NOT_FOUND_MESSAGE = "Treino não encontrado.";

/** Quem acessa o treino agendado, como na visualização do plano: o
 * treinador do plano sempre (mesmo sem vínculo atual ou com o cavalo
 * excluído, porque o treino é produção dele), e, com o cavalo ativo, os
 * treinadores vinculados, o proprietário e o atleta. Sem acesso,
 * 'not-found', para não revelar treinos de terceiros. A conta já deve ter
 * sido conferida.
 * @param {AuthenticatedUser} user Usuário autenticado.
 * @param {TrainingRecordDocument} record Treino agendado.
 * @param {ClientSession} session Sessão da transação, se houver.
 * @return {Promise<RecordViewer>} Relação de quem pede com o treino.
 */
export async function resolveRecordViewer(
  user: AuthenticatedUser,
  record: TrainingRecordDocument,
  session?: ClientSession
): Promise<RecordViewer> {
  const isTrainer = user.role === ROLES.trainer;
  if (isTrainer && record.treinador._id === user.uid) {
    return {role: "TREINADOR", isPlanTrainer: true, isAthlete: false};
  }

  const horse = await findActiveHorseById(record.cavalo._id, session);
  const relations = horse ? relationsOf(horse, user.uid) : [];
  if (isTrainer && relations.includes("TREINADOR")) {
    return {role: "TREINADOR", isPlanTrainer: false, isAthlete: false};
  }
  if (
    !isTrainer &&
    (relations.includes("PROPRIETARIO") || relations.includes("ATLETA"))
  ) {
    return {
      role: "RESPONSAVEL",
      isPlanTrainer: false,
      isAthlete: relations.includes("ATLETA"),
    };
  }
  throw new AppError("not-found", RECORD_NOT_FOUND_MESSAGE);
}
