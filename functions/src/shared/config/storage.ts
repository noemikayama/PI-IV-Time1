// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Leitura de um trecho do objeto (readRange, no lugar de
// readFirstBytes) e conferência da assinatura do formato (hasSignature).
// Alteração: URL de envio devolvida com os headers assinados
// (createSignedUpload), com opção de só aceitar caminho livre; data de
// criação em getObjectInfo; escolha de caminho livre (findFreePath).
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Acesso ao Cloud Storage e geração de URLs assinadas.
// -----------------------------------------------------------------------------

import {getStorage} from "firebase-admin/storage";
import {FILE_FORMATS} from "../constants/files";
import type {FileContentType} from "../constants/files";

// Resposta HTTP do Storage para leitura além do fim do arquivo.
const RANGE_NOT_SATISFIABLE = 416;

export type SignedUpload = {
    uploadUrl: string;
    // Headers que o app deve enviar no PUT, exatamente como assinados.
    headers: Record<string, string>;
};

/** Devolve o objeto do bucket padrão a partir do caminho salvo no MongoDB.
 * O caminho segue o formato do DD ('arquivos/...').
 * @param {string} path Caminho do arquivo.
 * @return {File} Objeto do bucket.
 */
function getFile(path: string) {
  return getStorage().bucket().file(path.replace(/^\/+/, ""));
}

/** Gera uma URL assinada (v4) para o app enviar um arquivo por PUT.
 * Com 'onlyIfAbsent', o Storage recusa o envio (412) se já existir arquivo no
 * caminho: um segundo envio pela mesma URL, ou para o mesmo caminho, não
 * sobrescreve o arquivo já conferido.
 * @param {string} path Caminho do objeto no bucket.
 * @param {string} contentType Content-Type exigido no envio.
 * @param {number} maxBytes Tamanho máximo aceito.
 * @param {number} ttlMs Validade da URL em milissegundos.
 * @param {boolean} onlyIfAbsent Se o envio só vale para caminho livre.
 * @return {Promise<SignedUpload>} URL e headers do envio.
 */
export async function createSignedUpload(
  path: string,
  contentType: string,
  maxBytes: number,
  ttlMs: number,
  onlyIfAbsent: boolean
): Promise<SignedUpload> {
  const extensionHeaders: Record<string, string> = {
    "x-goog-content-length-range": `0,${maxBytes}`,
    ...(onlyIfAbsent && {"x-goog-if-generation-match": "0"}),
  };
  const [uploadUrl] = await getFile(path).getSignedUrl({
    version: "v4",
    action: "write",
    expires: Date.now() + ttlMs,
    contentType,
    extensionHeaders,
  });
  return {
    uploadUrl,
    headers: {"Content-Type": contentType, ...extensionHeaders},
  };
}

/** Gera uma URL assinada de leitura com validade curta.
 * @param {string} path Caminho do objeto no bucket.
 * @param {number} ttlMs Validade da URL em milissegundos.
 */
export async function createReadUrl(
  path: string,
  ttlMs: number
): Promise<string> {
  const [url] = await getFile(path).getSignedUrl({
    version: "v4",
    action: "read",
    expires: Date.now() + ttlMs,
  });
  return url;
}

/** Lê tamanho, content-type e data de criação do objeto; devolve null se
 * não existir.
 * @param {string} path Caminho do objeto no bucket.
 */
export async function getObjectInfo(
  path: string
): Promise<{size: number; contentType: string; createdAt: Date} | null> {
  const file = getFile(path);
  const [exists] = await file.exists();
  if (!exists) return null;
  const [metadata] = await file.getMetadata();
  return {
    size: Number(metadata.size ?? 0),
    contentType: metadata.contentType ?? "",
    createdAt: new Date(metadata.timeCreated ?? 0),
  };
}

/** Escolhe o primeiro caminho livre da lista, na ordem informada.
 * Um arquivo enviado há menos de 'staleAfterMs' e ainda não confirmado é de
 * um envio em andamento e é pulado; um mais antigo foi abandonado e é apagado
 * para liberar o caminho.
 * @param {string[]} paths Caminhos candidatos (não gravados no documento).
 * @param {number} staleAfterMs Idade a partir da qual o arquivo é abandonado.
 * @return {Promise<string|null>} Caminho livre, ou null se todos estiverem
 * em uso por envios em andamento.
 */
export async function findFreePath(
  paths: string[],
  staleAfterMs: number
): Promise<string | null> {
  for (const path of paths) {
    const info = await getObjectInfo(path);
    if (!info) return path;
    if (Date.now() - info.createdAt.getTime() > staleAfterMs) {
      await deleteObject(path);
      return path;
    }
  }
  return null;
}

/** Lê um trecho do objeto, sem baixar o arquivo inteiro.
 * @param {string} path Caminho do objeto no bucket.
 * @param {number} start Posição do primeiro byte.
 * @param {number} length Quantidade de bytes.
 * @return {Promise<Buffer>} Bytes lidos (menos, ou nenhum, se o arquivo
 * acabar antes).
 */
export function readRange(
  path: string,
  start: number,
  length: number
): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    getFile(path)
      .createReadStream({start, end: start + length - 1})
      .on("data", (chunk: Buffer) => chunks.push(chunk))
      .on("error", (error: {code?: unknown}) => {
        // Início além do fim do arquivo: não há bytes a devolver.
        if (error.code === RANGE_NOT_SATISFIABLE) {
          resolve(Buffer.alloc(0));
        } else {
          reject(error);
        }
      })
      .on("end", () => resolve(Buffer.concat(chunks)));
  });
}

/** Confere se o objeto começa com a assinatura do formato informado.
 * @param {string} path Caminho do objeto no bucket.
 * @param {FileContentType} contentType Formato esperado.
 * @return {Promise<boolean>} Se os bytes conferem com o formato.
 */
export async function hasSignature(
  path: string,
  contentType: FileContentType
): Promise<boolean> {
  const {offset, bytes} = FILE_FORMATS[contentType].signature;
  const header = await readRange(path, offset, bytes.length);
  return header.length === bytes.length &&
    bytes.every((byte, i) => header[i] === byte);
}

/** Apaga o objeto, ignorando se ele já não existir.
 * @param {string} path Caminho do objeto no bucket.
 */
export async function deleteObject(path: string): Promise<void> {
  await getFile(path).delete({ignoreNotFound: true});
}
