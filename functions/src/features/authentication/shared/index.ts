// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação dos recursos compartilhados de autenticação inicial.
// ----------------------------------------------------------------------------- 

// Interface pública do que é compartilhado entre guardian e professional.
export {createAuthAccount, deleteAuthAccount} from "./services/authAccountService";
export {reserveEmail} from "./repositories/emailRepository";
export {asRecord, parseCredentials} from "./validations/validateCredentials";
export type {AccountType, Credentials, EmailReservation} from "./types";
