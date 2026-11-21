// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Extensão, assinatura e validade das URLs vindas de
// shared/constants/files.ts; conferência dos bytes com hasSignature.
// Alteração: A URL de envio só aceita caminho livre, e o caminho pula
// envios ainda em andamento.
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conferência da conta ativa do proprietário.
// Alteração: Verificação de acesso pelo helper central (horseAccess).
// Alteração: Leitura e acesso pelo getHorseForUser.
//
// Data: 27/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Envio, confirmação e remoção de imagens do cavalo.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {
  createReadUrl,
  createSignedUpload,
  deleteObject,
  findFreePath,
  getObjectInfo,
  hasSignature,
} from "../../../shared/config/storage";
import {ROLES} from "../../../shared/constants/roles";
import {
  FILE_FORMATS,
  READ_URL_TTL_MS,
  UNCONFIRMED_FILE_TTL_MS,
  UPLOAD_URL_TTL_MS,
} from "../../../shared/constants/files";
import {AppError} from "../../../shared/errors/AppError";
import {
  IMAGE_MAX_BYTES,
  IMAGE_ROOT,
  MAX_HORSE_IMAGES,
} from "../constants/images";
import {
  addHorseImage,
  findActiveHorseById,
  removeHorseImage,
} from "../repositories/horseRepository";
import type {
  HorseDocument,
  HorseImageContentType,
  HorseImageFileInput,
  HorseImageUploadInput,
  HorseImageUploadResult,
  HorseImageView,
} from "../types";
import {getHorseForUser, HORSE_RULES} from "./horseAccess";

const IMAGE_INDEX_PATTERN = /imagem_(\d+)\.(jpg|png)$/;

/** Caminho de uma imagem do cavalo, no formato do DD.
 * @param {ObjectId} id _id do cavalo.
 * @param {number} indice Índice da imagem.
 * @param {HorseImageContentType} contentType Formato da imagem.
 * @return {string} Caminho da imagem.
 */
function imagePath(
  id: ObjectId,
  indice: number,
  contentType: HorseImageContentType
): string {
  const {extension} = FILE_FORMATS[contentType];
  return `${IMAGE_ROOT}/${id.toHexString()}/imagem_${indice}.${extension}`;
}

/** Garante que o caminho é um dos que o servidor gera para o cavalo.
 * @param {ObjectId} id _id do cavalo.
 * @param {string} caminho Caminho informado pelo app.
 * @return {HorseImageContentType} Formato esperado pela extensão.
 */
function assertOwnedPath(
  id: ObjectId,
  caminho: string
): HorseImageContentType {
  const match = IMAGE_INDEX_PATTERN.exec(caminho);
  const indice = Number(match?.[1]);
  const contentType = match?.[2] === "png" ? "image/png" : "image/jpeg";
  // Escrito na forma positiva para que NaN (caminho sem índice) seja recusado.
  const valid = indice >= 1 &&
    indice <= MAX_HORSE_IMAGES &&
    caminho === imagePath(id, indice, contentType);
  if (!valid) {
    throw new AppError("invalid-argument", "Caminho inválido.");
  }
  return contentType;
}

/** Escolhe o caminho da nova imagem: o menor índice que não está gravado no
 * cavalo nem reservado por um envio em andamento.
 * @param {HorseDocument} horse Cavalo carregado.
 * @param {HorseImageContentType} contentType Formato da imagem.
 * @return {Promise<string>} Caminho livre.
 */
async function nextImagePath(
  horse: HorseDocument,
  contentType: HorseImageContentType
): Promise<string> {
  const used = new Set(
    horse.imagens.map((path) => Number(IMAGE_INDEX_PATTERN.exec(path)?.[1]))
  );
  const candidates: string[] = [];
  for (let i = 1; i <= MAX_HORSE_IMAGES; i++) {
    if (!used.has(i)) candidates.push(imagePath(horse._id, i, contentType));
  }
  if (candidates.length === 0) {
    throw new AppError(
      "invalid-argument",
      `Limite de ${MAX_HORSE_IMAGES} imagens atingido.`
    );
  }

  const caminho = await findFreePath(candidates, UNCONFIRMED_FILE_TTL_MS);
  if (!caminho) {
    throw new AppError(
      "failed-precondition",
      "Há envios em andamento. Confirme-os antes de enviar outra imagem."
    );
  }
  return caminho;
}

/** Carrega o cavalo ativo e garante que o usuário é o proprietário, com a
 * conta ativa.
 * @param {string} uid UID do responsável.
 * @param {ObjectId} id _id do cavalo.
 * @return {Promise<HorseDocument>} Cavalo do proprietário.
 */
async function loadOwnedHorse(
  uid: string,
  id: ObjectId
): Promise<HorseDocument> {
  const {horse} = await getHorseForUser(
    {uid, role: ROLES.guardian},
    id,
    HORSE_RULES.alterarImagens
  );
  return horse;
}

/** Confere se o arquivo enviado tem o tamanho e o formato esperados.
 * @param {string} caminho Caminho da imagem no Storage.
 * @param {HorseImageContentType} contentType Formato esperado.
 * @return {Promise<boolean>} Se o arquivo é uma imagem válida.
 */
async function isValidImage(
  caminho: string,
  contentType: HorseImageContentType
): Promise<boolean> {
  const info = await getObjectInfo(caminho);
  if (!info) throw new AppError("not-found", "Imagem não enviada.");
  if (
    info.size === 0 ||
    info.size > IMAGE_MAX_BYTES ||
    info.contentType !== contentType
  ) {
    return false;
  }
  return hasSignature(caminho, contentType);
}

/** Converte o caminho gravado para o formato enviado ao app.
 * @param {string} caminho Caminho da imagem no Storage.
 * @return {Promise<HorseImageView>} Imagem com URL de leitura.
 */
export async function toHorseImageView(
  caminho: string
): Promise<HorseImageView> {
  return {caminho, url: await createReadUrl(caminho, READ_URL_TTL_MS)};
}

/** Gera a URL para o app enviar a imagem direto ao Storage.
 * @param {string} uid UID do responsável autenticado.
 * @param {HorseImageUploadInput} input Dados validados.
 * @return {Promise<HorseImageUploadResult>} Dados para o envio da imagem.
 */
export async function createHorseImageUploadService(
  uid: string,
  input: HorseImageUploadInput
): Promise<HorseImageUploadResult> {
  const horse = await loadOwnedHorse(uid, input.id);
  const caminho = await nextImagePath(horse, input.contentType);
  // Só aceita caminho livre: a imagem conferida não pode ser sobrescrita.
  const upload = await createSignedUpload(
    caminho,
    input.contentType,
    IMAGE_MAX_BYTES,
    UPLOAD_URL_TTL_MS,
    true
  );

  return {caminho, ...upload};
}

/** Confere a imagem enviada e grava o caminho no cavalo.
 * @param {string} uid UID do responsável autenticado.
 * @param {HorseImageFileInput} input Dados validados.
 * @return {Promise<HorseImageView>} Imagem confirmada.
 */
export async function confirmHorseImageService(
  uid: string,
  input: HorseImageFileInput
): Promise<HorseImageView> {
  const horse = await loadOwnedHorse(uid, input.id);
  const {caminho} = input;
  const contentType = assertOwnedPath(horse._id, caminho);

  if (!(await isValidImage(caminho, contentType))) {
    // A URL de envio não sobrescreve arquivos, mas a referência é removida
    // por garantia (arquivos enviados antes dessa regra).
    await deleteObject(caminho);
    await removeHorseImage(horse._id, caminho);
    throw new AppError(
      "invalid-argument",
      "O arquivo enviado não é uma imagem JPEG ou PNG de até " +
        `${IMAGE_MAX_BYTES / (1024 * 1024)} MB.`
    );
  }

  if (!horse.imagens.includes(caminho)) {
    const saved = await addHorseImage(horse._id, caminho, MAX_HORSE_IMAGES);
    // Uma confirmação simultânea do mesmo caminho também resulta em false.
    const current = saved ? null : await findActiveHorseById(horse._id);
    if (!saved && !current?.imagens.includes(caminho)) {
      await deleteObject(caminho);
      throw new AppError("invalid-argument", "Limite de imagens atingido.");
    }
  }

  return toHorseImageView(caminho);
}

/** Remove a imagem do cavalo e do Storage.
 * @param {string} uid UID do responsável autenticado.
 * @param {HorseImageFileInput} input Dados validados.
 * @return {Promise<{removido: true}>} Confirmação da remoção.
 */
export async function removeHorseImageService(
  uid: string,
  input: HorseImageFileInput
): Promise<{removido: true}> {
  const horse = await loadOwnedHorse(uid, input.id);
  const {caminho} = input;
  assertOwnedPath(horse._id, caminho);

  if (!horse.imagens.includes(caminho)) {
    throw new AppError("not-found", "Imagem não encontrada.");
  }

  await removeHorseImage(horse._id, caminho);
  await deleteObject(caminho);
  return {removido: true};
}
