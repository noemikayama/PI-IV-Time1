// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da consulta de detalhes do treinamento.
// Alteração: Exportação da edição do treinamento e das cópias usadas pelos
// planos.
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Registros por período (findRecordsByHorses e
// findRecordsByTrainer), usados pela home e pela agenda, e execuções
// recentes para o histórico da agenda.
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportações usadas pela feature de planos; a consulta do
// autor do plano ativo foi para a feature de planos.
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do cadastro de treinamentos.
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação dos treinos do dia de um cavalo no plano atual.
// Alteração: Exportação da consulta do autor do plano ativo do cavalo.
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
  closePlannedRecords,
  ensureTrainingRecordIndexes,
  insertTrainingRecords,
  findDayRecordsByHorsePlan,
  findRecentExecutionsByHorses,
  findRecentExecutionsByTrainer,
  findRecordsByHorses,
  findRecordsByTrainer,
} from "./repositories/trainingRecordRepository";
export {findTrainerTrainings} from "./repositories/trainingRepository";
export {
  toRecordTraining,
  toTrainingSnapshot,
} from "./services/trainingSnapshot";
export type {
  ExecutionCount,
  FeedbackCount,
  HorseExecutionCounts,
  NewTrainingRecord,
  PerformedExercise,
  RecentExecutionRecord,
  TrainingRecordStatus,
  TrainingRecordSummary,
  TrainingRecordTraining,
} from "./types/trainingRecord";
export type {TrainingDocument, TrainingSnapshot} from "./types/training";
export {registerTraining} from "./handlers/registerTraining";
export {getTrainingDetails} from "./handlers/getTrainingDetails";
export {updateTraining} from "./handlers/updateTraining";
