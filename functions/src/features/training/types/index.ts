// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Exportação dos tipos da execução e do feedback.
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação dos tipos da consulta de detalhes do treinamento.
// Alteração: Exportação dos tipos da edição do treinamento.
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
  TrainingContent,
  TrainingDetailsCargo,
  TrainingDetailsExercise,
  TrainingDetailsExerciseKind,
  TrainingDetailsInput,
  TrainingDetailsResult,
  TrainingDocument,
  TrainingExercise,
  TrainingExerciseView,
  TrainingRegistrationInput,
  TrainingSnapshot,
  TrainingTrainerRef,
  TrainingUpdateInput,
  TrainingView,
} from "./training";
export type {
  ExecutionCount,
  ExecutionReport,
  ExerciseCompletion,
  FeedbackCount,
  HorseExecutionCounts,
  NewTrainingRecord,
  PendingFeedbackRecord,
  PerformedExercise,
  RecentExecutionRecord,
  RecordAccountRef,
  ReportedRecordStatus,
  TrainingFeedback,
  TrainingRecordDocument,
  TrainingRecordStatus,
  TrainingRecordSummary,
  TrainingRecordTraining,
} from "./trainingRecord";
