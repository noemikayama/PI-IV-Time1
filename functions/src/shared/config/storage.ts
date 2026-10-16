// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Acesso ao Cloud Storage e geração de URLs assinadas.
// -----------------------------------------------------------------------------

import {getStorage} from "firebase-admin/storage";

/** Devolve o objeto do bucket padrão a partir do caminho salvo no MongoDB.
 * O caminho segue o formato do DD ('arquivos/...').
 * @param {string} path Caminho do arquivo.
 * @return {File} Objeto do bucket.
 */
function getFile(path: string) {
  return getStorage().bucket().file(path.replace(/^\/+/, ""));
}

/** Gera uma URL assinada (v4) para o app enviar um arquivo por PUT.
 * @param {string} path Caminho do objeto no bucket.
 * @param {string} contentType Content-Type exigido no envio.
 * @param {number} maxBytes Tamanho máximo aceito.
 * @param {number} ttlMs Validade da URL em milissegundos.
 */
export async function createUploadUrl(
  path: string,
  contentType: string,
  maxBytes: number,
  ttlMs: number
): Promise<string> {
  const [url] = await getFile(path).getSignedUrl({
    version: "v4",
    action: "write",
    expires: Date.now() + ttlMs,
    contentType,
    extensionHeaders: {"x-goog-content-length-range": `0,${maxBytes}`},
  });
  return url;
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

/** Lê tamanho e content-type do objeto; devolve null se não existir.
 * @param {string} path Caminho do objeto no bucket.
 */
export async function getObjectInfo(
  path: string
): Promise<{size: number; contentType: string} | null> {
  const file = getFile(path);
  const [exists] = await file.exists();
  if (!exists) return null;
  const [metadata] = await file.getMetadata();
  return {
    size: Number(metadata.size ?? 0),
    contentType: metadata.contentType ?? "",
  };
}

/** Lê os primeiros bytes do objeto.
 * @param {string} path Caminho do objeto no bucket.
 * @param {number} length Quantidade de bytes.
 * @return {Promise<Buffer>} Bytes iniciais do objeto.
 */
export function readFirstBytes(path: string, length: number): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    getFile(path)
      .createReadStream({start: 0, end: length - 1})
      .on("data", (chunk: Buffer) => chunks.push(chunk))
      .on("error", reject)
      .on("end", () => resolve(Buffer.concat(chunks)));
  });
}

/** Apaga o objeto, ignorando se ele já não existir.
 * @param {string} path Caminho do objeto no bucket.
 */
export async function deleteObject(path: string): Promise<void> {
  await getFile(path).delete({ignoreNotFound: true});
}
