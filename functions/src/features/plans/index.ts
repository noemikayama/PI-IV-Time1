// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Exportação do objetivo do plano para o treino agendado.
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da visualização, do cancelamento e da edição do
// plano.
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
  findPlanObjective,
  isActivePlanAuthor,
} from "./repositories/planRepository";
export {createTrainingPlan} from "./handlers/createTrainingPlan";
export {listHorseEvaluations} from "./handlers/listHorseEvaluations";
export {listTrainingGallery} from "./handlers/listTrainingGallery";
export {getTrainingPlanDetails} from "./handlers/getTrainingPlanDetails";
export {cancelTrainingPlan} from "./handlers/cancelTrainingPlan";
export {updateTrainingPlan} from "./handlers/updateTrainingPlan";
export type {ActivePlanSummary} from "./types";
