// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Busca de uma modalidade pelo _id (cadastro de cavalos).
//
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta de modalidades por ID (somente leitura).
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta das modalidades cadastradas.
// -----------------------------------------------------------------------------

// Coleção 'modalidades': catálogo pequeno, lido por inteiro (sem índices).
import type {ObjectId} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import type {ModalityDocument} from "../types";

/** Busca todas as modalidades em ordem alfabética (considera acentos).
 * @return {Promise<ModalityDocument[]>} Modalidades cadastradas.
 */
export async function findAllModalities(): Promise<ModalityDocument[]> {
  const db = await getDatabase();
  return db
    .collection<ModalityDocument>(COLLECTIONS.Modalidades)
    .find({})
    .collation({locale: "pt"})
    .sort({nome: 1})
    .toArray();
}

/** Busca uma modalidade pelo _id.
 * @param {ObjectId} id _id da modalidade.
 */
export async function findModalityById(
  id: ObjectId
): Promise<ModalityDocument | null> {
  const db = await getDatabase();
  return db
    .collection<ModalityDocument>(COLLECTIONS.Modalidades)
    .findOne({_id: id});
/** Busca as modalidades cadastradas entre os IDs informados.
 * IDs sem cadastro simplesmente não aparecem no resultado.
 * @param {ObjectId[]} ids IDs das modalidades.
 * @return {Promise<ModalityDocument[]>} Modalidades encontradas.
 */
export async function findModalitiesByIds(
  ids: ObjectId[]
): Promise<ModalityDocument[]> {
  if (ids.length === 0) return [];

  const db = await getDatabase();
  return db
    .collection<ModalityDocument>(COLLECTIONS.Modalidades)
    .find({_id: {$in: ids}})
    .toArray();
}
