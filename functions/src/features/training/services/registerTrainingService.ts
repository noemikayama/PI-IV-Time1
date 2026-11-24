// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cópia do exercício movida para trainingSnapshot (usada também
// pela edição).
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cadastro de treinamentos pelo treinador.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {loadTrainerExercises} from "../../exercises";
import {assertActiveAccount} from "../../horses";
import {
  ensureTrainingIndexes,
  insertTraining,
} from "../repositories/trainingRepository";
import type {
  NewTraining,
  TrainingDocument,
  TrainingRegistrationInput,
  TrainingView,
} from "../types";
import {toTrainingExercise} from "./trainingSnapshot";

/** Converte o documento no formato do app (o callable não converte
 * ObjectId nem Date).
 * @param {TrainingDocument} training Treinamento gravado.
 * @return {TrainingView} Treinamento para o app.
 */
function toTrainingView(training: TrainingDocument): TrainingView {
  const {_id, treinador, exercicios, criadoEm, atualizadoEm, ...rest} =
    training;
  return {
    id: _id.toHexString(),
    ...rest,
    treinador: {
      id: treinador._id,
      codigo: treinador.codigo,
      nome: treinador.nome,
    },
    exercicios: exercicios.map(({_id: exerciseId, ...exercise}) => ({
      id: exerciseId.toHexString(),
      ...exercise,
    })),
    criadoEm: criadoEm.toISOString(),
    atualizadoEm: atualizadoEm.toISOString(),
  };
}

/** Cadastra o treinamento do treinador. Os exercícios precisam ser dele e
 * estar ativos; genéricos e específicos de cavalos diferentes podem ser
 * combinados. A duração estimada não é comparada com a soma dos exercícios.
 * @param {string} uid UID do treinador autenticado.
 * @param {TrainingRegistrationInput} input Dados validados do cadastro.
 * @return {Promise<TrainingView>} Treinamento criado.
 */
export async function registerTrainingService(
  uid: string,
  input: TrainingRegistrationInput
): Promise<TrainingView> {
  const trainer = await assertActiveAccount(uid, ROLES.trainer);
  const [exercises] = await Promise.all([
    loadTrainerExercises(uid, input.exercicios),
    ensureTrainingIndexes(),
  ]);

  const now = new Date();
  const training: NewTraining = {
    _id: new ObjectId(),
    titulo: input.titulo,
    ...(input.descricao && {descricao: input.descricao}),
    orientacoes: input.orientacoes,
    duracaoEstimadaMinutos: input.duracaoEstimadaMinutos,
    treinador: {_id: uid, codigo: trainer.codigo, nome: trainer.nome},
    exercicios: exercises.map(toTrainingExercise),
    criadoEm: now,
    atualizadoEm: now,
  };

  // A transação garante que o código sequencial só é consumido se o
  // treinamento for gravado.
  const codigo = await runInTransaction((session) =>
    insertTraining(training, session)
  );

  return toTrainingView({...training, codigo});
}
