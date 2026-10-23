// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Montagem da referência resumida da modalidade do cavalo.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {findModalityById} from "../../modalities";
import type {HorseDocument} from "../types";

/** Busca a modalidade e devolve a cópia resumida gravada no cavalo.
 * @param {ObjectId} id _id da modalidade.
 * @return {Object} Referência {_id, codigo, nome}.
 */
export async function resolveModality(
  id: ObjectId
): Promise<NonNullable<HorseDocument["modalidade"]>> {
  const modality = await findModalityById(id);
  if (!modality) {
    throw new AppError("invalid-argument", "Modalidade não encontrada.");
  }
  return {_id: modality._id, codigo: modality.codigo, nome: modality.nome};
}
