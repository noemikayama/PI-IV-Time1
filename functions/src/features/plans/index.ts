// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação dos planos ativos para a agenda.
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportações da feature de planos de treinamento.
// -----------------------------------------------------------------------------

export {
  findActivePlansByHorses,
  findActivePlansByTrainer,
  isActivePlanAuthor,
} from "./repositories/planRepository";
export {createTrainingPlan} from "./handlers/createTrainingPlan";
export {listHorseEvaluations} from "./handlers/listHorseEvaluations";
export {listTrainingGallery} from "./handlers/listTrainingGallery";
export type {ActivePlanSummary} from "./types";
