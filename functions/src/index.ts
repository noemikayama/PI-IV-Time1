// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
  updateHorse,
  getHorse,
  createHorseImageUpload,
  confirmHorseImage,
  removeHorseImage,
} from "./features/horses";
export {
  getDashboard,
} from "./features/dashboard";
