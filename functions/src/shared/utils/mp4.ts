// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Leitura da duração de um vídeo MP4 sem baixar o arquivo e
// identificação de arquivos QuickTime (.mov).
// -----------------------------------------------------------------------------

// Um MP4 é uma sequência de caixas: 4 bytes de tamanho, 4 de tipo e o
// conteúdo. A duração fica em moov > mvhd. Como o celular costuma gravar o
// 'moov' no fim do arquivo, as caixas são percorridas pelos cabeçalhos, lendo
// só alguns bytes de cada uma.

// Lê 'length' bytes a partir de 'start' (por exemplo, readRange do Storage).
export type ByteReader = (start: number, length: number) => Promise<Buffer>;

type Box = {type: string; start: number; headerSize: number; size: number};

// Limite de caixas visitadas por nível; protege contra arquivos malformados.
const MAX_BOXES = 64;

/** Lê o cabeçalho da caixa que começa em 'start'.
 * @param {ByteReader} read Leitor de bytes do arquivo.
 * @param {number} start Posição da caixa.
 * @param {number} end Fim do contêiner que a contém.
 * @return {Promise<Box|null>} Caixa, ou null se o cabeçalho for inválido.
 */
async function readBox(
  read: ByteReader,
  start: number,
  end: number
): Promise<Box | null> {
  const header = await read(start, 16);
  if (header.length < 8) return null;

  let size = header.readUInt32BE(0);
  let headerSize = 8;
  if (size === 1) {
    // Tamanho em 64 bits logo após o tipo.
    if (header.length < 16) return null;
    size = Number(header.readBigUInt64BE(8));
    headerSize = 16;
  } else if (size === 0) {
    // A caixa vai até o fim do contêiner.
    size = end - start;
  }

  if (size < headerSize || start + size > end) return null;
  return {type: header.toString("latin1", 4, 8), start, headerSize, size};
}

/** Procura uma caixa pelo tipo entre 'start' e 'end', num único nível.
 * @param {ByteReader} read Leitor de bytes do arquivo.
 * @param {string} type Tipo procurado (4 caracteres).
 * @param {number} start Início da busca.
 * @param {number} end Fim do contêiner.
 * @return {Promise<Box|null>} Caixa encontrada ou null.
 */
async function findBox(
  read: ByteReader,
  type: string,
  start: number,
  end: number
): Promise<Box | null> {
  let offset = start;
  for (let i = 0; i < MAX_BOXES && offset < end; i++) {
    const box = await readBox(read, offset, end);
    if (!box) return null;
    if (box.type === type) return box;
    offset += box.size;
  }
  return null;
}

/** Indica se o arquivo é um QuickTime (.mov): a caixa 'ftyp' declara a marca
 * 'qt  '. Ele tem a mesma estrutura do MP4, mas nem todo aparelho o
 * reproduz.
 * @param {ByteReader} read Leitor de bytes do arquivo.
 * @return {Promise<boolean>} Se a marca principal é a do QuickTime.
 */
export async function isQuickTime(read: ByteReader): Promise<boolean> {
  // ftyp: tamanho (4 bytes), tipo (4) e a marca principal (4).
  const brand = await read(8, 4);
  return brand.toString("latin1") === "qt  ";
}

/** Lê a duração do vídeo, em segundos, a partir de moov > mvhd.
 * @param {ByteReader} read Leitor de bytes do arquivo.
 * @param {number} fileSize Tamanho do arquivo em bytes.
 * @return {Promise<number|null>} Duração, ou null se não for possível ler.
 */
export async function readMp4DurationSeconds(
  read: ByteReader,
  fileSize: number
): Promise<number | null> {
  const moov = await findBox(read, "moov", 0, fileSize);
  if (!moov) return null;
  const mvhd = await findBox(
    read,
    "mvhd",
    moov.start + moov.headerSize,
    moov.start + moov.size
  );
  if (!mvhd) return null;

  // mvhd: versão (1 byte) e flags (3); depois criação, modificação, escala
  // e duração, com tempos de 32 bits na versão 0 e de 64 bits na versão 1.
  const body = await read(mvhd.start + mvhd.headerSize, 32);
  if (body.length < 20) return null;

  let timescale: number;
  let duration: number;
  if (body.readUInt8(0) === 1) {
    if (body.length < 32) return null;
    timescale = body.readUInt32BE(20);
    duration = Number(body.readBigUInt64BE(24));
  } else {
    timescale = body.readUInt32BE(12);
    duration = body.readUInt32BE(16);
  }

  if (timescale === 0 || duration === 0) return null;
  return duration / timescale;
}
