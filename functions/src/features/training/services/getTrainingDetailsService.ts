// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Detalhes do treinamento para o treinador e o responsável.
// Alteração: Tipo e cavalo dos exercícios para o treinador; acesso movido
// para trainingAccess, compartilhado com a edição.
// -----------------------------------------------------------------------------

import {findExerciseKinds} from "../../exercises";
import type {ExerciseKindSource} from "../../exercises";
import type {
  TrainingDetailsCargo,
  TrainingDetailsInput,
  TrainingDetailsResult,
  TrainingDocument,
} from "../types";
import {loadAccessibleTraining} from "./trainingAccess";

/** Lê o tipo e o cavalo dos exercícios do treinamento, só para o treinador
 * (a tela de edição usa esses dados).
 * @param {TrainingDocument} training Treinamento encontrado.
 * @param {TrainingDetailsCargo} cargo Cargo do usuário.
 * @return {Promise<Map<string, ExerciseKindSource>>} Por _id do exercício.
 */
async function loadKinds(
  training: TrainingDocument,
  cargo: TrainingDetailsCargo
): Promise<Map<string, ExerciseKindSource>> {
  if (cargo !== "treinador") return new Map();
  const kinds = await findExerciseKinds(
    training.exercicios.map((exercise) => exercise._id)
  );
  return new Map(kinds.map((kind) => [kind._id.toHexString(), kind]));
}

/** Converte o documento no formato da tela (códigos como string, sem
 * ObjectId nem Date). 'tipo' e 'cavalo' ficam null para o responsável.
 * @param {TrainingDocument} training Treinamento.
 * @param {TrainingDetailsCargo} cargo Cargo do usuário.
 * @return {Promise<TrainingDetailsResult>} Detalhes para o app.
 */
export async function toTrainingDetails(
  training: TrainingDocument,
  cargo: TrainingDetailsCargo
): Promise<TrainingDetailsResult> {
  const kinds = await loadKinds(training, cargo);
  return {
    codigo: String(training.codigo),
    titulo: training.titulo,
    descricao: training.descricao ?? "",
    duracaoEstimada: training.duracaoEstimadaMinutos,
    exercicios: training.exercicios.map((exercise) => {
      const kind = kinds.get(exercise._id.toHexString());
      return {
        codigo: String(exercise.codigo),
        nome: exercise.nome,
        duracao: exercise.duracaoPadraoMinutos,
        descricao: exercise.descricao,
        tipo: kind ?
          (kind.privacidade === "ESPECIFICO" ? "especifico" : "generico") :
          null,
        cavalo: kind?.cavalo ?
          {codigo: kind.cavalo.codigo, nome: kind.cavalo.nome} :
          null,
      };
    }),
    orientacoes: training.orientacoes,
    cargo,
  };
}

/** Detalhes do treinamento, iguais para os dois perfis; muda o 'cargo' e,
 * para o responsável, 'tipo' e 'cavalo' dos exercícios vêm null.
 * @param {string} uid UID do usuário autenticado.
 * @param {TrainingDetailsInput} input Código validado.
 * @return {Promise<TrainingDetailsResult>} Detalhes do treinamento.
 */
export async function getTrainingDetailsService(
  uid: string,
  input: TrainingDetailsInput
): Promise<TrainingDetailsResult> {
  const {training, cargo} = await loadAccessibleTraining(
    uid,
    input.codigo,
    false
  );
  return toTrainingDetails(training, cargo);
}
