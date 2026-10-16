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
// Alteração: Definição dos papéis usados pelas contas do sistema.
// -----------------------------------------------------------------------------

export const ROLES = {
  guardian: "guardian",
  trainer: "trainer",
  admin: "admin",
} as const;

export type Role = (typeof ROLES)[keyof typeof ROLES];
