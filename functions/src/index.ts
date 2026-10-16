// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
  getTrainerProfile,
  login,
  getHome,
  confirmTrainerAttachment,
  createTrainerAttachmentUpload,
  removeTrainerAttachment,
} from "./features/authentication";
export {
  getModalities,
} from "./features/modalities";
