// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação dos tipos de treinamentos e de registros de treino.
// -----------------------------------------------------------------------------

export type {
  NewTraining,
  TrainingDocument,
  TrainingExercise,
  TrainingExerciseView,
  TrainingRegistrationInput,
  TrainingTrainerRef,
  TrainingView,
} from "./training";
export type {
  DayTrainingRecord,
  ExecutionCount,
  FeedbackCount,
  HorseExecutionCounts,
  TrainingRecordStatus,
} from "./trainingRecord";
