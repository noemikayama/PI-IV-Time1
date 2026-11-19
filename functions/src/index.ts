// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Exportação da conferência do microchip no servidor Java.
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da galeria de exercícios, do tempo total dos
// exercícios selecionados e do cadastro de treinamentos.
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do cadastro de exercícios e do envio, da confirmação
// e da remoção de mídias do exercício.
//
// Data: 04/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do desvínculo de atleta ou treinador do cavalo.
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: getHorseProfile (perfil completo do cavalo) no lugar de
// getHorse, getHorseCurrentPlan e listHorseEvaluations.
// Alteração: Exportação da inclusão de saúde, da exclusão e do plano atual
// do cavalo, e da criação e do histórico de avaliações.
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação dos vínculos e da lista de cavalos.
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do dashboard de evolução.
// Alteração: Exportação da edição do perfil do responsável.
//
// Data: 27/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do envio, da confirmação e da remoção de imagens
// de cavalos.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do cadastro, da edição e da consulta de cavalos.
//
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da edição de modalidades do responsável.
// Alteração: Exportação da função de logout.
//
// Data: 20/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da função de recuperação de senha.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do cadastro de responsáveis e profissionais.
// -----------------------------------------------------------------------------

export {
  registerGuardian,
  registerTrainer,
  getGuardianProfile,
  updateGuardianModalities,
  updateGuardianProfile,
  getTrainerProfile,
  login,
  getHome,
  confirmTrainerAttachment,
  createTrainerAttachmentUpload,
  removeTrainerAttachment,
  updateTrainerProfile,
  requestPasswordReset,
  logout,
} from "./features/authentication";
export {
  getModalities,
} from "./features/modalities";
export {
  registerHorse,
  validateMicrochip,
  updateHorse,
  getHorseProfile,
  listHorses,
  updateHorseLinks,
  removeHorseLink,
  addHorseHealthEntry,
  deleteHorse,
  createHorseImageUpload,
  confirmHorseImage,
  removeHorseImage,
} from "./features/horses";
export {
  createHorseEvaluation,
} from "./features/evaluations";
export {
  getDashboard,
} from "./features/dashboard";
export {
  registerExercise,
  createExerciseMediaUpload,
  confirmExerciseMedia,
  removeExerciseMedia,
  listExerciseGallery,
  sumExerciseDurations,
} from "./features/exercises";
export {
  registerTraining,
} from "./features/training";
