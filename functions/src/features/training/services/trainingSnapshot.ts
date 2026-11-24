// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cópias do exercício no treinamento e do treinamento no plano e
// nos registros de treino, usadas nos cadastros e na edição do treinamento.
// -----------------------------------------------------------------------------

import type {ExerciseDocument} from "../../exercises";
import type {
  PerformedExercise,
  TrainingRecordTraining,
} from "../types/trainingRecord";
import type {
  TrainingDocument,
  TrainingExercise,
  TrainingSnapshot,
} from "../types/training";

/** Copia os dados do exercício no momento da inclusão (DD 3.5): edições
 * posteriores no exercício não alteram o treinamento.
 * @param {ExerciseDocument} exercise Exercício de origem.
 * @return {TrainingExercise} Exercício em uso.
 */
export const toTrainingExercise = (
  exercise: ExerciseDocument
): TrainingExercise => ({
  _id: exercise._id,
  codigo: exercise.codigo,
  nome: exercise.nome,
  descricao: exercise.descricao,
  orientacoes: exercise.orientacoes,
  duracaoPadraoMinutos: exercise.duracaoPadraoMinutos,
});

/** Copia o treinamento, com os exercícios, para o item do planejamento
 * (DD 3.6). A edição do treinamento renova a cópia dos planos em andamento.
 * @param {TrainingDocument} training Treinamento de origem.
 * @return {TrainingSnapshot} Cópia guardada no item.
 */
export const toTrainingSnapshot = (
  training: TrainingDocument
): TrainingSnapshot => ({
  _id: training._id,
  codigo: training.codigo,
  titulo: training.titulo,
  ...(training.descricao && {descricao: training.descricao}),
  orientacoes: training.orientacoes,
  duracaoEstimadaMinutos: training.duracaoEstimadaMinutos,
  exercicios: training.exercicios,
});

/** Separa a cópia do item nos campos do registro de treino (DD 3.7 e 3.9):
 * o treinamento sem os exercícios e os exercícios ainda PENDENTE.
 * @param {TrainingSnapshot} snapshot Cópia do item do planejamento.
 * @return {object} 'treinamento' e 'exercicios' do registro.
 */
export function toRecordTraining(snapshot: TrainingSnapshot): {
  treinamento: TrainingRecordTraining;
  exercicios: PerformedExercise[];
} {
  const {exercicios, ...treinamento} = snapshot;
  return {
    treinamento,
    exercicios: exercicios.map((exercicio) => ({
      exercicio,
      realizacao: "PENDENTE",
    })),
  };
}
