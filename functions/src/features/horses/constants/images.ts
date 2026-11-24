// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Extensões, assinaturas e validade das URLs movidas para
// shared/constants/files.ts; aqui ficam só as regras do cavalo.
//
// Data: 27/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Regras das imagens do cavalo.
// -----------------------------------------------------------------------------

import type {HorseImageContentType} from "../types";

// Formatos aceitos para as imagens do cavalo.
export const IMAGE_CONTENT_TYPES: readonly HorseImageContentType[] = [
  "image/jpeg",
  "image/png",
];

export const IMAGE_MAX_BYTES = 5 * 1024 * 1024;

// Raiz das imagens no Storage (formato do DD).
export const IMAGE_ROOT = "/fotos/cavalos";

export const MAX_HORSE_IMAGES = 10;
