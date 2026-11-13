// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Envio, confirmação e remoção das mídias (imagens e vídeos) do
// exercício. A URL de envio só aceita caminho livre; vídeos .mov são
// recusados.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {
  createReadUrl,
  createSignedUpload,
  deleteObject,
  findFreePath,
  getObjectInfo,
  hasSignature,
  readRange,
} from "../../../shared/config/storage";
import {
  FILE_FORMATS,
  READ_URL_TTL_MS,
  UNCONFIRMED_FILE_TTL_MS,
  UPLOAD_URL_TTL_MS,
} from "../../../shared/constants/files";
import {AppError} from "../../../shared/errors/AppError";
import {
  isQuickTime,
  readMp4DurationSeconds,
} from "../../../shared/utils/mp4";
import type {ByteReader} from "../../../shared/utils/mp4";
import {
  MEDIA_FIELDS,
  MEDIA_LIMITS,
  VIDEO_DURATION_TOLERANCE_SECONDS,
  VIDEO_MAX_SECONDS,
} from "../constants/media";
import {
  addExerciseMedia,
  findActiveExerciseById,
  removeExerciseMedia,
} from "../repositories/exerciseRepository";
import type {
  ExerciseDocument,
  ExerciseMediaContentType,
  ExerciseMediaField,
  ExerciseMediaFileInput,
  ExerciseMediaUploadInput,
  ExerciseMediaUploadResult,
  ExerciseMediaView,
} from "../types";

const CONTENT_TYPES = Object.keys(MEDIA_FIELDS) as ExerciseMediaContentType[];
const MEDIA_INDEX_PATTERN = /_(\d+)\.[a-z0-9]+$/;

// Nome de cada campo nas mensagens.
const FIELD_LABELS: Record<ExerciseMediaField, string> = {
  imagens: "imagens",
  videos: "vídeos",
};

/** Caminho de uma mídia do exercício, no formato do DD.
 * @param {number} codigo Código do exercício.
 * @param {ExerciseMediaContentType} contentType Formato da mídia.
 * @param {number} indice Índice da mídia no campo.
 * @return {string} Caminho da mídia.
 */
function mediaPath(
  codigo: number,
  contentType: ExerciseMediaContentType,
  indice: number
): string {
  const {root} = MEDIA_LIMITS[MEDIA_FIELDS[contentType]];
  const {extension} = FILE_FORMATS[contentType];
  return `${root}/${codigo}_${indice}.${extension}`;
}

/** Extrai o índice do caminho ('<codigo>_<indice>.<extensão>').
 * @param {string} caminho Caminho da mídia.
 * @return {number} Índice, ou NaN se o caminho não tiver um.
 */
function mediaIndex(caminho: string): number {
  return Number(MEDIA_INDEX_PATTERN.exec(caminho)?.[1]);
}

/** Garante que o caminho é um dos que o servidor gera para o exercício.
 * @param {number} codigo Código do exercício.
 * @param {string} caminho Caminho informado pelo app.
 * @return {ExerciseMediaContentType} Formato esperado pela extensão.
 */
function assertOwnedPath(
  codigo: number,
  caminho: string
): ExerciseMediaContentType {
  const indice = mediaIndex(caminho);
  const contentType = CONTENT_TYPES.find(
    (type) => caminho === mediaPath(codigo, type, indice)
  );
  // Escrito na forma positiva para que NaN (caminho sem índice) seja recusado.
  const valid = contentType !== undefined &&
    indice >= 1 &&
    indice <= MEDIA_LIMITS[MEDIA_FIELDS[contentType]].maxFiles;
  if (!valid) {
    throw new AppError("invalid-argument", "Caminho inválido.");
  }
  return contentType;
}

/** Escolhe o caminho da nova mídia: o menor índice que não está gravado no
 * exercício nem reservado por um envio em andamento.
 * @param {ExerciseDocument} exercise Exercício carregado.
 * @param {ExerciseMediaContentType} contentType Formato da mídia.
 * @return {Promise<string>} Caminho livre.
 */
async function nextMediaPath(
  exercise: ExerciseDocument,
  contentType: ExerciseMediaContentType
): Promise<string> {
  const field = MEDIA_FIELDS[contentType];
  const {maxFiles} = MEDIA_LIMITS[field];
  const used = new Set(exercise[field].map(mediaIndex));
  const candidates: string[] = [];
  for (let i = 1; i <= maxFiles; i++) {
    if (!used.has(i)) {
      candidates.push(mediaPath(exercise.codigo, contentType, i));
    }
  }
  if (candidates.length === 0) {
    throw new AppError(
      "invalid-argument",
      `Limite de ${maxFiles} ${FIELD_LABELS[field]} atingido.`
    );
  }

  const caminho = await findFreePath(candidates, UNCONFIRMED_FILE_TTL_MS);
  if (!caminho) {
    throw new AppError(
      "failed-precondition",
      "Há envios em andamento. Confirme-os antes de enviar outra mídia."
    );
  }
  return caminho;
}

/** Carrega o exercício ativo e garante que o usuário é quem o cadastrou.
 * @param {string} uid UID do treinador.
 * @param {ObjectId} id _id do exercício.
 * @return {Promise<ExerciseDocument>} Exercício do treinador.
 */
async function loadOwnedExercise(
  uid: string,
  id: ObjectId
): Promise<ExerciseDocument> {
  const exercise = await findActiveExerciseById(id);
  if (!exercise) {
    throw new AppError("not-found", "Exercício não encontrado.");
  }
  if (exercise.treinador?._id !== uid) {
    throw new AppError(
      "permission-denied",
      "Apenas o treinador que cadastrou o exercício pode alterar as mídias."
    );
  }
  return exercise;
}

/** Confere tamanho, formato e, no vídeo, a duração do arquivo enviado.
 * @param {string} caminho Caminho da mídia no Storage.
 * @param {ExerciseMediaContentType} contentType Formato esperado.
 * @return {Promise<string|null>} Motivo da recusa, ou null se válido.
 */
async function findMediaProblem(
  caminho: string,
  contentType: ExerciseMediaContentType
): Promise<string | null> {
  const field = MEDIA_FIELDS[contentType];
  const {maxBytes} = MEDIA_LIMITS[field];
  const info = await getObjectInfo(caminho);
  if (!info) throw new AppError("not-found", "Arquivo não enviado.");

  const validFile = info.size > 0 &&
    info.size <= maxBytes &&
    info.contentType === contentType &&
    (await hasSignature(caminho, contentType));
  if (!validFile) {
    const megabytes = maxBytes / (1024 * 1024);
    return field === "imagens" ?
      `O arquivo enviado não é uma imagem JPEG ou PNG de até ${megabytes} MB.` :
      `O arquivo enviado não é um vídeo MP4 de até ${megabytes} MB.`;
  }

  if (field === "videos") {
    const read: ByteReader = (start, length) =>
      readRange(caminho, start, length);
    if (await isQuickTime(read)) {
      return "Vídeos .mov não são aceitos. Converta o vídeo para MP4.";
    }
    const seconds = await readMp4DurationSeconds(read, info.size);
    if (seconds === null) {
      return "Não foi possível ler a duração do vídeo.";
    }
    if (seconds > VIDEO_MAX_SECONDS + VIDEO_DURATION_TOLERANCE_SECONDS) {
      return `O vídeo deve ter até ${VIDEO_MAX_SECONDS} segundos.`;
    }
  }
  return null;
}

/** Converte o caminho gravado para o formato enviado ao app.
 * @param {string} caminho Caminho da mídia no Storage.
 * @return {Promise<ExerciseMediaView>} Mídia com URL de leitura.
 */
export async function toExerciseMediaView(
  caminho: string
): Promise<ExerciseMediaView> {
  return {caminho, url: await createReadUrl(caminho, READ_URL_TTL_MS)};
}

/** Gera a URL para o app enviar a mídia direto ao Storage.
 * @param {string} uid UID do treinador autenticado.
 * @param {ExerciseMediaUploadInput} input Dados validados.
 * @return {Promise<ExerciseMediaUploadResult>} Dados para o envio.
 */
export async function createExerciseMediaUploadService(
  uid: string,
  input: ExerciseMediaUploadInput
): Promise<ExerciseMediaUploadResult> {
  const exercise = await loadOwnedExercise(uid, input.id);
  const {contentType} = input;
  const {maxBytes} = MEDIA_LIMITS[MEDIA_FIELDS[contentType]];
  const caminho = await nextMediaPath(exercise, contentType);
  // Só aceita caminho livre: o arquivo conferido não pode ser sobrescrito.
  const upload = await createSignedUpload(
    caminho,
    contentType,
    maxBytes,
    UPLOAD_URL_TTL_MS,
    true
  );

  return {caminho, ...upload};
}

/** Confere a mídia enviada e grava o caminho no exercício.
 * @param {string} uid UID do treinador autenticado.
 * @param {ExerciseMediaFileInput} input Dados validados.
 * @return {Promise<ExerciseMediaView>} Mídia confirmada.
 */
export async function confirmExerciseMediaService(
  uid: string,
  input: ExerciseMediaFileInput
): Promise<ExerciseMediaView> {
  const exercise = await loadOwnedExercise(uid, input.id);
  const {caminho} = input;
  const contentType = assertOwnedPath(exercise.codigo, caminho);
  const field = MEDIA_FIELDS[contentType];

  const problem = await findMediaProblem(caminho, contentType);
  if (problem) {
    // A URL de envio não sobrescreve arquivos, mas a referência é removida
    // por garantia (arquivos enviados antes dessa regra).
    await deleteObject(caminho);
    await removeExerciseMedia(exercise._id, field, caminho);
    throw new AppError("invalid-argument", problem);
  }

  if (!exercise[field].includes(caminho)) {
    const {maxFiles} = MEDIA_LIMITS[field];
    const saved = await addExerciseMedia(
      exercise._id,
      field,
      caminho,
      maxFiles
    );
    // Uma confirmação simultânea do mesmo caminho também resulta em false.
    const current = saved ? null : await findActiveExerciseById(exercise._id);
    if (!saved && !current?.[field].includes(caminho)) {
      await deleteObject(caminho);
      throw new AppError(
        "invalid-argument",
        `Limite de ${maxFiles} ${FIELD_LABELS[field]} atingido.`
      );
    }
  }

  return toExerciseMediaView(caminho);
}

/** Remove a mídia do exercício e do Storage.
 * @param {string} uid UID do treinador autenticado.
 * @param {ExerciseMediaFileInput} input Dados validados.
 * @return {Promise<{removido: true}>} Confirmação da remoção.
 */
export async function removeExerciseMediaService(
  uid: string,
  input: ExerciseMediaFileInput
): Promise<{removido: true}> {
  const exercise = await loadOwnedExercise(uid, input.id);
  const {caminho} = input;
  const field = MEDIA_FIELDS[assertOwnedPath(exercise.codigo, caminho)];

  if (!exercise[field].includes(caminho)) {
    throw new AppError("not-found", "Mídia não encontrada.");
  }

  await removeExerciseMedia(exercise._id, field, caminho);
  await deleteObject(caminho);
  return {removido: true};
}
