// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 29/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conferência do caminho, carga do treinador ativo e conversão dos
// anexos exportadas para a consulta e a edição do perfil.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Envio, confirmação e remoção de PDFs do treinador.
// -----------------------------------------------------------------------------

import type {ClientSession} from "mongodb";
import {
  createReadUrl,
  createUploadUrl,
  deleteObject,
  getObjectInfo,
  readFirstBytes,
} from "../../../../shared/config/storage";
import {AppError} from "../../../../shared/errors/AppError";
import {
  ATTACHMENT_CONTENT_TYPE,
  ATTACHMENT_MAX_BYTES,
  ATTACHMENT_ROOT,
  MAX_CERTIFICATIONS,
  READ_URL_TTL_MS,
  UPLOAD_URL_TTL_MS,
} from "../constants/attachments";
import {
  addTrainerCertification,
  findTrainerById,
  removeTrainerFile,
  setTrainerExperience,
} from "../repositories/trainerRepository";
import type {
  AttachmentFileInput,
  AttachmentType,
  AttachmentUploadInput,
  AttachmentUploadResult,
  TrainerAttachmentView,
  TrainerDocument,
  TrainerProfile,
} from "../types";

/** Caminho do PDF de experiências (único), no formato do DD.
 * @param {string} uid UID do usuário.
 * @return {string} Caminho do PDF de experiências.
 */
function experiencePath(uid: string): string {
  return `${ATTACHMENT_ROOT}/${uid}/experiencia_1.pdf`;
}

/** Caminho do PDF de uma certificação, no formato do DD.
 * @param {string} uid UID do usuário.
 * @param {number} indice Índice da certificação.
 * @return {string} Caminho do PDF da certificação.
 */
function certificationPath(uid: string, indice: number): string {
  return `${ATTACHMENT_ROOT}/${uid}/certificacao_${indice}.pdf`;
}

/** Indica se o caminho é o de uma certificação válida do usuário.
 * @param {string} uid UID do usuário.
 * @param {string} caminho Caminho informado pelo app.
 * @return {boolean} Se o caminho é de uma certificação válida.
 */
function isCertificationPath(uid: string, caminho: string): boolean {
  const indice = Number(/certificacao_(\d+)\.pdf$/.exec(caminho)?.[1]);
  return indice >= 1 &&
    indice <= MAX_CERTIFICATIONS &&
    caminho === certificationPath(uid, indice);
}

/** Garante que o caminho é um dos que o servidor gera para o usuário.
 * @param {string} uid UID do usuário.
 * @param {AttachmentType} tipo Tipo do anexo.
 * @param {string} caminho Caminho informado pelo app.
 * @return {void}
 */
export function assertOwnedPath(
  uid: string,
  tipo: AttachmentType,
  caminho: string
): void {
  const valid = tipo === "experiencias" ?
    caminho === experiencePath(uid) :
    isCertificationPath(uid, caminho);
  if (!valid) throw new AppError("invalid-argument", "Caminho inválido.");
}

/** Escolhe o menor índice livre para uma nova certificação.
 * @param {string[]} certificacoes Caminhos já gravados.
 * @return {number} Menor índice livre.
 */
function nextCertificationIndex(certificacoes: string[]): number {
  const used = new Set(
    certificacoes.map(
      (path) => Number(/certificacao_(\d+)\.pdf$/.exec(path)?.[1])
    )
  );
  for (let i = 1; i <= MAX_CERTIFICATIONS; i++) {
    if (!used.has(i)) return i;
  }
  throw new AppError(
    "invalid-argument",
    `Limite de ${MAX_CERTIFICATIONS} certificações atingido.`
  );
}

/** Carrega o treinador e garante que a conta está ativa.
 * @param {string} uid UID do usuário.
 * @param {ClientSession} session Sessão da transação, se houver.
 * @return {Promise<TrainerDocument>} Treinador ativo.
 */
export async function loadActiveTrainer(
  uid: string,
  session?: ClientSession
): Promise<TrainerDocument> {
  const trainer = await findTrainerById(uid, session);
  if (!trainer) throw new AppError("not-found", "Perfil não encontrado.");
  if (trainer.situacaoProfissional === "INATIVO") {
    throw new AppError("permission-denied", "Cadastro inativo.");
  }
  return trainer;
}

/** Indica se o caminho já está gravado no treinador.
 * @param {TrainerDocument} trainer Treinador carregado.
 * @param {AttachmentType} tipo Tipo do anexo.
 * @param {string} caminho Caminho do arquivo.
 * @return {boolean} Se o anexo está registrado.
 */
function hasFile(
  trainer: TrainerDocument,
  tipo: AttachmentType,
  caminho: string
): boolean {
  return tipo === "experiencias" ?
    trainer.experiencias === caminho :
    trainer.certificacoes.includes(caminho);
}

/** Converte o caminho gravado para o formato enviado ao app.
 * @param {string} caminho Caminho do arquivo no Storage.
 * @return {Promise<TrainerAttachmentView>} Anexo com URL de leitura.
 */
export async function toAttachmentView(
  caminho: string
): Promise<TrainerAttachmentView> {
  return {caminho, url: await createReadUrl(caminho, READ_URL_TTL_MS)};
}

/** Converte a experiência e as certificações gravadas para o formato do app.
 * @param {TrainerDocument} trainer Treinador carregado.
 * @return {Promise<Object>} Anexos com URL de leitura.
 */
export async function toAttachmentViews(
  trainer: Pick<TrainerDocument, "experiencias" | "certificacoes">
): Promise<Pick<TrainerProfile, "experiencias" | "certificacoes">> {
  const [experiencias, certificacoes] = await Promise.all([
    typeof trainer.experiencias === "string" ?
      toAttachmentView(trainer.experiencias) :
      null,
    Promise.all(trainer.certificacoes.map(toAttachmentView)),
  ]);
  return {experiencias, certificacoes};
}

/** Gera a URL para o app enviar o PDF direto ao Storage.
 * @param {string} uid UID do usuário.
 * @param {AttachmentUploadInput} input Dados validados.
 * @return {Promise<AttachmentUploadResult>} Dados para o envio do PDF.
 */
export async function createTrainerAttachmentUploadService(
  uid: string,
  input: AttachmentUploadInput
): Promise<AttachmentUploadResult> {
  const trainer = await loadActiveTrainer(uid);
  const caminho = input.tipo === "experiencias" ?
    experiencePath(uid) :
    certificationPath(uid, nextCertificationIndex(trainer.certificacoes));
  const uploadUrl = await createUploadUrl(
    caminho,
    ATTACHMENT_CONTENT_TYPE,
    ATTACHMENT_MAX_BYTES,
    UPLOAD_URL_TTL_MS
  );

  return {
    caminho,
    uploadUrl,
    headers: {
      "Content-Type": ATTACHMENT_CONTENT_TYPE,
      "x-goog-content-length-range": `0,${ATTACHMENT_MAX_BYTES}`,
    },
  };
}

/** Confere o arquivo enviado e grava o caminho no MongoDB.
 * @param {string} uid UID do usuário.
 * @param {AttachmentFileInput} input Dados validados.
 * @return {Promise<TrainerAttachmentView>} Anexo confirmado.
 */
export async function confirmTrainerAttachmentService(
  uid: string,
  input: AttachmentFileInput
): Promise<TrainerAttachmentView> {
  const trainer = await loadActiveTrainer(uid);
  const {tipo, caminho} = input;
  assertOwnedPath(uid, tipo, caminho);

  const info = await getObjectInfo(caminho);
  if (!info) throw new AppError("not-found", "Arquivo não enviado.");

  const validSize = info.size > 0 && info.size <= ATTACHMENT_MAX_BYTES;
  const header = validSize ? await readFirstBytes(caminho, 5) : null;
  if (
    !validSize ||
    info.contentType !== ATTACHMENT_CONTENT_TYPE ||
    header?.toString("latin1") !== "%PDF-"
  ) {
    // A experiência reaproveita o caminho: o envio inválido sobrescreveu o
    // arquivo anterior, então a referência também é removida.
    await deleteObject(caminho);
    await removeTrainerFile(uid, tipo, caminho);
    throw new AppError("invalid-argument", "O arquivo enviado não é um PDF.");
  }

  if (tipo === "experiencias") {
    await setTrainerExperience(uid, caminho);
  } else if (!hasFile(trainer, tipo, caminho)) {
    const saved = await addTrainerCertification(
      uid,
      caminho,
      MAX_CERTIFICATIONS
    );
    if (!saved) {
      await deleteObject(caminho);
      throw new AppError(
        "invalid-argument",
        "Limite de certificações atingido."
      );
    }
  }

  return toAttachmentView(caminho);
}

/** Remove o anexo do MongoDB e do Storage.
 * @param {string} uid UID do usuário.
 * @param {AttachmentFileInput} input Dados validados.
 * @return {Promise<{removido: true}>} Confirmação da remoção.
 */
export async function removeTrainerAttachmentService(
  uid: string,
  input: AttachmentFileInput
): Promise<{removido: true}> {
  const trainer = await loadActiveTrainer(uid);
  const {tipo, caminho} = input;
  assertOwnedPath(uid, tipo, caminho);

  if (!hasFile(trainer, tipo, caminho)) {
    throw new AppError("not-found", "Anexo não encontrado.");
  }

  await removeTrainerFile(uid, tipo, caminho);
  await deleteObject(caminho);
  return {removido: true};
}
