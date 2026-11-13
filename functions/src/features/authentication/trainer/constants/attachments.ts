// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validade das URLs movida para shared/constants/files.ts.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Regras dos anexos em PDF do treinador.
// -----------------------------------------------------------------------------

export const ATTACHMENT_CONTENT_TYPE = "application/pdf";
export const ATTACHMENT_MAX_BYTES = 10 * 1024 * 1024;

// Raiz dos arquivos no Storage (formato do DD).
export const ATTACHMENT_ROOT = "/arquivos/treinadores";

// experiencias: 1 arquivo; certificacoes: até este limite.
export const MAX_CERTIFICATIONS = 10;
