// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Acesso ao treinamento, compartilhado pelos detalhes e pela
// edição.
// -----------------------------------------------------------------------------

import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
// Import direto dos repositories, como em horseAccess: os index.ts de
// authentication alcançam a home, que importa esta feature.
import {
  findGuardianHomeSource,
} from "../../authentication/guardian/repositories/guardianRepository";
import {
  findAccountByUid,
} from "../../authentication/shared/repositories/accountRepository";
import {
  findTrainerHomeSource,
} from "../../authentication/trainer/repositories/trainerRepository";
import {
  hasTrainingRecordForHorses,
} from "../repositories/trainingRecordRepository";
import {findTrainingByCode} from "../repositories/trainingRepository";
import type {TrainingDetailsCargo, TrainingDocument} from "../types";

/** Diz se o usuário tem acesso ao treinamento. O treinador acessa os que
 * criou e os agendados (registros_treino) para algum cavalo em que ele é o
 * treinador. O responsável acessa os agendados para algum cavalo em que é
 * proprietário ou atleta.
 * @param {TrainingDocument} training Treinamento encontrado.
 * @param {string} uid UID do usuário autenticado.
 * @param {TrainingDetailsCargo} cargo Cargo lido da conta.
 * @return {Promise<boolean>} Se o acesso é permitido.
 */
async function canAccess(
  training: TrainingDocument,
  uid: string,
  cargo: TrainingDetailsCargo
): Promise<boolean> {
  if (cargo === "treinador" && training.treinador._id === uid) return true;
  const owner = cargo === "treinador" ?
    await findTrainerHomeSource(uid) :
    await findGuardianHomeSource(uid);
  const horseIds = (owner?.cavalos ?? []).map((horse) => horse._id);
  return hasTrainingRecordForHorses(training._id, horseIds);
}

/** Carrega o treinamento pelo código e confere o acesso. O cargo vem da
 * conta no MongoDB (o _id é o UID), nunca do cliente nem do claim do token.
 * Treinamento inexistente ou sem acesso é 'not-found', para não revelar
 * treinamentos de terceiros.
 * @param {string} uid UID do usuário autenticado.
 * @param {number} codigo Código do treinamento.
 * @param {boolean} trainerOnly Se só o treinador pode seguir.
 * @return {Promise<object>} Treinamento e cargo do usuário.
 */
export async function loadAccessibleTraining(
  uid: string,
  codigo: number,
  trainerOnly: boolean
): Promise<{training: TrainingDocument; cargo: TrainingDetailsCargo}> {
  const [account, training] = await Promise.all([
    findAccountByUid(uid),
    findTrainingByCode(codigo),
  ]);
  if (!account?.active) {
    throw new AppError("unauthenticated", "Conta inativa ou inexistente.");
  }

  const cargo: TrainingDetailsCargo =
    account.role === ROLES.trainer ? "treinador" : "responsavel";
  if (trainerOnly && cargo !== "treinador") {
    throw new AppError(
      "permission-denied",
      "Apenas treinadores podem editar treinamentos."
    );
  }
  if (!training || !(await canAccess(training, uid, cargo))) {
    throw new AppError("not-found", "Treinamento não encontrado.");
  }
  return {training, cargo};
}
