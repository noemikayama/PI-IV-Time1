// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação dos índices de uma coleção uma única vez por processo.
// -----------------------------------------------------------------------------

// Os índices do DD são criados pela aplicação, na primeira operação que
// depende deles. createIndexes não altera um índice que já existe, então
// repetir é inofensivo; o cache só evita uma ida ao banco a cada chamada.
// Deve rodar fora de transação.
import type {IndexDescription} from "mongodb";
import {getDatabase} from "../config/mongodb";

const ready = new Map<string, Promise<void>>();

/** Garante os índices informados na coleção, uma vez por processo. A chave
 * do cache inclui os nomes dos índices, então duas features podem garantir
 * índices diferentes na mesma coleção. Se a criação falhar, a próxima
 * chamada tenta de novo.
 * @param {string} collection Nome da coleção.
 * @param {IndexDescription[]} indexes Índices, cada um com 'name'.
 * @return {Promise<void>} Resolvida quando os índices existirem.
 */
export function ensureIndexesOnce(
  collection: string,
  indexes: IndexDescription[]
): Promise<void> {
  const key = `${collection}:${indexes.map((index) => index.name).join(",")}`;
  let pending = ready.get(key);
  if (!pending) {
    pending = getDatabase()
      .then((db) => db.collection(collection).createIndexes(indexes))
      .then(() => undefined)
      .catch((error) => {
        ready.delete(key);
        throw error;
      });
    ready.set(key, pending);
  }
  return pending;
}
