// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da busca e da validação de e-mail.
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação dos recursos usados na edição do perfil.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação dos mappers da home.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação dos recursos compartilhados de autenticação.
// -----------------------------------------------------------------------------

// Interface pública do que é compartilhado entre guardian e trainer.
export {
  createAuthAccount,
  deleteAuthAccount,
  updateAuthDisplayName,
} from "./services/authAccountService";
export {findEmail, reserveEmail} from "./repositories/emailRepository";
export {
  asRecord,
  assertAllowedFields,
  parseCredentials,
  parseEmail,
  parseFullName,
} from "./validations/validateCredentials";
export type {AccountType, Credentials, EmailReservation} from "./types";
export {HOME_LIST_LIMIT, toProgress, toRef} from "./services/homeMappers";
