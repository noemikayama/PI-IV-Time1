// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Formatos de arquivo aceitos no Storage, validade das URLs
// assinadas e prazo de arquivo não confirmado, comuns a todas as features.
// -----------------------------------------------------------------------------

// Raiz, tamanho máximo e quantidade de arquivos são regras de cada feature e
// ficam nas constantes dela.

export type FileContentType =
  | "image/jpeg"
  | "image/png"
  | "video/mp4"
  | "application/pdf";

type FileFormat = {
    // Extensão gravada no caminho.
    extension: string;
    // Bytes que identificam o formato, a partir de 'offset'.
    signature: {offset: number; bytes: number[]};
};

export const FILE_FORMATS: Record<FileContentType, FileFormat> = {
  "image/jpeg": {
    extension: "jpg",
    signature: {offset: 0, bytes: [0xff, 0xd8, 0xff]},
  },
  "image/png": {
    extension: "png",
    signature: {
      offset: 0,
      bytes: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
    },
  },
  // No MP4, os 4 primeiros bytes são o tamanho da caixa 'ftyp', que vem
  // logo depois.
  "video/mp4": {
    extension: "mp4",
    signature: {offset: 4, bytes: [0x66, 0x74, 0x79, 0x70]},
  },
  // "%PDF-"
  "application/pdf": {
    extension: "pdf",
    signature: {offset: 0, bytes: [0x25, 0x50, 0x44, 0x46, 0x2d]},
  },
};

export const UPLOAD_URL_TTL_MS = 10 * 60 * 1000;
export const READ_URL_TTL_MS = 15 * 60 * 1000;

// Arquivo enviado e não confirmado depois desse prazo é considerado
// abandonado: o caminho pode ser reaproveitado por um novo envio.
export const UNCONFIRMED_FILE_TTL_MS = 30 * 60 * 1000;
