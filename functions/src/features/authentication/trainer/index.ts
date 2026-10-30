// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 29/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da edição do perfil do treinador.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da função de cadastro de profissionais com
// o storage das certificações e experiências
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da função de cadastro de profissionais.
// -----------------------------------------------------------------------------

export {registerTrainer} from "./handlers/registerTrainer";
export {getTrainerProfile} from "./handlers/getTrainerProfile";
export {confirmTrainerAttachment} from
  "./handlers/confirmTrainerAttachmentUpload";
export {createTrainerAttachmentUpload} from
  "./handlers/createTrainerAttachmentUpload";
export {removeTrainerAttachment} from
  "./handlers/removeTrainerAttachment";
export {updateTrainerProfile} from "./handlers/updateTrainerProfile";
