// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Regras das mídias (imagens e vídeos) do exercício. Extensões,
// assinaturas e validade das URLs vêm de shared/constants/files.ts.
// -----------------------------------------------------------------------------

import type {ExerciseMediaContentType, ExerciseMediaField} from "../types";

type MediaLimits = {
    // Raiz no Storage (formato do DD).
    root: string;
    maxBytes: number;
    maxFiles: number;
};

// Formatos aceitos e o campo do documento que guarda o caminho de cada um.
export const MEDIA_FIELDS: Record<
  ExerciseMediaContentType,
  ExerciseMediaField
> = {
  "image/jpeg": "imagens",
  "image/png": "imagens",
  "video/mp4": "videos",
};

export const MEDIA_LIMITS: Record<ExerciseMediaField, MediaLimits> = {
  imagens: {
    root: "/fotos/exercicios",
    maxBytes: 5 * 1024 * 1024,
    maxFiles: 10,
  },
  videos: {
    root: "/videos/exercicios",
    maxBytes: 50 * 1024 * 1024,
    maxFiles: 3,
  },
};

// Duração máxima do vídeo, lida do próprio arquivo na confirmação. A folga
// cobre o arredondamento da gravação no aparelho.
export const VIDEO_MAX_SECONDS = 30;
export const VIDEO_DURATION_TOLERANCE_SECONDS = 0.5;
