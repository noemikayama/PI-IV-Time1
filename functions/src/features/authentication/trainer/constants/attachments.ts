// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Regras dos anexos em PDF do treinador.
// -----------------------------------------------------------------------------

export const ATTACHMENT_CONTENT_TYPE = "application/pdf";
export const ATTACHMENT_MAX_BYTES = 10 * 1024 * 1024;
export const UPLOAD_URL_TTL_MS = 10 * 60 * 1000;
export const READ_URL_TTL_MS = 15 * 60 * 1000;

// Raiz dos arquivos no Storage (formato do DD).
export const ATTACHMENT_ROOT = "/arquivos/treinadores";

// experiencias: 1 arquivo; certificacoes: até este limite.
export const MAX_CERTIFICATIONS = 10;
