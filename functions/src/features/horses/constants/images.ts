// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Regras das imagens do cavalo.
// -----------------------------------------------------------------------------

import type {HorseImageContentType} from "../types";

// Extensão gravada no caminho para cada formato aceito.
export const IMAGE_EXTENSIONS: Record<HorseImageContentType, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
};

// Bytes iniciais que identificam cada formato.
export const IMAGE_SIGNATURES: Record<HorseImageContentType, number[]> = {
  "image/jpeg": [0xff, 0xd8, 0xff],
  "image/png": [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
};

export const IMAGE_MAX_BYTES = 5 * 1024 * 1024;
export const UPLOAD_URL_TTL_MS = 10 * 60 * 1000;
export const READ_URL_TTL_MS = 15 * 60 * 1000;

// Raiz das imagens no Storage (formato do DD).
export const IMAGE_ROOT = "/fotos/cavalos";

export const MAX_HORSE_IMAGES = 10;
