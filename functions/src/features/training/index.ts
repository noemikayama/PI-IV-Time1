// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da regra de treino executado para o dashboard.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Interface pública da feature de treinos.
// -----------------------------------------------------------------------------

export {
  EXECUTED_STATUSES,
  countHorseExecutions,
  countTrainerExecutions,
  countTrainerFeedbacks,
  findDayRecordsByHorses,
  findDayRecordsByTrainer,
} from "./repositories/trainingRecordRepository";
export type {
  DayTrainingRecord,
  ExecutionCount,
  FeedbackCount,
  HorseExecutionCounts,
  TrainingRecordStatus,
} from "./types/trainingRecord";
