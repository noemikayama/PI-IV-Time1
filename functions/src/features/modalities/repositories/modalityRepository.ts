// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta das modalidades cadastradas.
// -----------------------------------------------------------------------------

// Coleção 'modalidades': catálogo pequeno, lido por inteiro (sem índices).
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
