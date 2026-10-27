// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da edição de modalidades do responsável.
// Alteração: Exportação do logout.
//
// Data: 20/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da recuperação de senha.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do cadastro de responsáveis e treinadores.
// -----------------------------------------------------------------------------

export {registerGuardian} from "./guardian";
export {getGuardianProfile} from "./guardian";
export {updateGuardianModalities} from "./guardian";
export {registerTrainer} from "./trainer";
export {getTrainerProfile} from "./trainer";
export {confirmTrainerAttachment} from "./trainer";
export {createTrainerAttachmentUpload} from "./trainer";
export {removeTrainerAttachment} from "./trainer";
export {login} from "./shared/handlers/login";
export {getHome} from "./shared/handlers/getHome";
export {logout} from "./shared/handlers/logout";
export {
  requestPasswordReset,
} from "./shared/handlers/requestPasswordReset";
