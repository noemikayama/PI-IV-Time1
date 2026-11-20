// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação dos tipos da consulta de detalhes do treinamento.
// Alteração: Exportação dos tipos da edição do treinamento.
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
  DayTrainingRecord,
  ExecutionCount,
  FeedbackCount,
  HorseExecutionCounts,
  NewTrainingRecord,
  PerformedExercise,
  TrainingRecordDocument,
  TrainingRecordStatus,
  TrainingRecordTraining,
} from "./trainingRecord";
