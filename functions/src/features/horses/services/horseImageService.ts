// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
  createUploadUrl,
  deleteObject,
  getObjectInfo,
  readFirstBytes,
} from "../../../shared/config/storage";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {
  IMAGE_EXTENSIONS,
  IMAGE_MAX_BYTES,
  IMAGE_ROOT,
  IMAGE_SIGNATURES,
  MAX_HORSE_IMAGES,
  READ_URL_TTL_MS,
  UPLOAD_URL_TTL_MS,
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
  const extension = IMAGE_EXTENSIONS[contentType];
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

/** Escolhe o menor índice livre para uma nova imagem.
 * @param {string[]} imagens Caminhos já gravados.
 * @return {number} Menor índice livre.
 */
function nextImageIndex(imagens: string[]): number {
  const used = new Set(
    imagens.map((path) => Number(IMAGE_INDEX_PATTERN.exec(path)?.[1]))
  );
  for (let i = 1; i <= MAX_HORSE_IMAGES; i++) {
    if (!used.has(i)) return i;
  }
  throw new AppError(
    "invalid-argument",
    `Limite de ${MAX_HORSE_IMAGES} imagens atingido.`
  );
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
  const signature = IMAGE_SIGNATURES[contentType];
  const header = await readFirstBytes(caminho, signature.length);
  return signature.every((byte, i) => header[i] === byte);
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
  const caminho = imagePath(
    horse._id,
    nextImageIndex(horse.imagens),
    input.contentType
  );
  const uploadUrl = await createUploadUrl(
    caminho,
    input.contentType,
    IMAGE_MAX_BYTES,
    UPLOAD_URL_TTL_MS
  );

  return {
    caminho,
    uploadUrl,
    headers: {
      "Content-Type": input.contentType,
      "x-goog-content-length-range": `0,${IMAGE_MAX_BYTES}`,
    },
  };
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
    // Um envio para um caminho já gravado sobrescreveu a imagem anterior,
    // então a referência também é removida.
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
