// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Interface pública da feature de treinos.
// -----------------------------------------------------------------------------

export {
  countHorseExecutions,
  countProfessionalExecutions,
  countProfessionalFeedbacks,
  findDayRecordsByHorses,
  findDayRecordsByProfessional,
} from "./repositories/trainingRecordRepository";
export type {
  DayTrainingRecord,
  ExecutionCount,
  FeedbackCount,
  HorseExecutionCounts,
  TrainingRecordStatus,
} from "./types/trainingRecord";
