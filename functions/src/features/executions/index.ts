// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Exportação das callables do treino agendado: consulta,
// execução, feedback e execuções que esperam feedback.
// -----------------------------------------------------------------------------

export {getTrainingRecord} from "./handlers/getTrainingRecord";
export {
  registerTrainingExecution,
} from "./handlers/registerTrainingExecution";
export {registerTrainingFeedback} from "./handlers/registerTrainingFeedback";
export {listPendingFeedbacks} from "./handlers/listPendingFeedbacks";
