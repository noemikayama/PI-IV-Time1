// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: TrainingRecordSummary no lugar de DayTrainingRecord e
// exportação de RecentExecutionRecord.
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da cópia do treinamento e do documento do registro.
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
  TrainingSnapshot,
  TrainingTrainerRef,
  TrainingView,
} from "./training";
export type {
  ExecutionCount,
  FeedbackCount,
  HorseExecutionCounts,
  NewTrainingRecord,
  PerformedExercise,
  RecentExecutionRecord,
  TrainingRecordDocument,
  TrainingRecordStatus,
  TrainingRecordSummary,
  TrainingRecordTraining,
} from "./trainingRecord";
