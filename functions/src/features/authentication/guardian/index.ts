// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da edição do perfil do responsável.
// Alteração: Exportação da consulta resumida usada pela home e pelo
// dashboard.
//
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da edição de modalidades do responsável.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da função de cadastro de responsáveis.
// -----------------------------------------------------------------------------

export {registerGuardian} from "./handlers/registerGuardian";
export {getGuardianProfile} from "./handlers/getGuardianProfile";
export {updateGuardianModalities} from "./handlers/updateGuardianModalities";
export {updateGuardianProfile} from "./handlers/updateGuardianProfile";
export {
  findGuardianHomeSource,
} from "./repositories/guardianRepository";
export type {GuardianHomeSource} from "./types";
