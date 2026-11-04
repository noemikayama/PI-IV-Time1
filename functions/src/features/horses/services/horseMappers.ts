// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: toHorseView substituído por buildHorseProfile (horseProfile.ts).
// Alteração: Relação TREINADOR explícita na consulta.
// Alteração: Datas de início e de fim do plano atual.
// Alteração: Cards da lista de cavalos e início do vínculo de quem consulta.
// Alteração: relationsOf movido para horseAccess.ts.
// Alteração: HorseListSource importado de types.
//
// Data: 27/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Imagens enviadas com URL assinada de leitura.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conversão do documento do cavalo para o formato do app.
// -----------------------------------------------------------------------------

import type {
  GuardianHorseCard,
  HorseListSource,
  RefView,
  TrainerHorseCard,
} from "../types";
import {relationsOf} from "./horseAccess";
import {toHorseImageView} from "./horseImageService";

type Ref = {_id: unknown; codigo: number; nome: string};

export const toRefView = (ref: Ref): RefView => ({
  id: String(ref._id),
  codigo: ref.codigo,
  nome: ref.nome,
});

/** Início do vínculo de quem consulta: o cadastro para o proprietário e a
 * data do vínculo para atleta e treinador. Vínculos gravados antes dessa
 * data existir usam o cadastro do cavalo.
 * @param {HorseListSource} horse Cavalo da lista.
 * @param {string} uid UID de quem consulta.
 * @return {Date} Início do vínculo.
 */
function linkedSince(horse: HorseListSource, uid: string): Date {
  if (horse.proprietario._id === uid) return horse.criadoEm;
  if (horse.atleta?._id === uid) {
    return horse.atleta.vinculadoEm ?? horse.criadoEm;
  }
  const trainer = horse.treinadores.find((item) => item._id === uid);
  return trainer?.vinculadoEm ?? horse.criadoEm;
}

/** Campos comuns dos cards: só a primeira imagem ganha URL de leitura.
 * @param {HorseListSource} horse Cavalo da lista.
 * @param {string} uid UID de quem consulta.
 */
async function toHorseCardBase(horse: HorseListSource, uid: string) {
  const [first] = horse.imagens;
  return {
    id: horse._id.toHexString(),
    nome: horse.nome,
    foto: first ? await toHorseImageView(first) : null,
    modalidade: horse.modalidade ? toRefView(horse.modalidade) : null,
    responsabilidades: relationsOf(horse, uid),
    vinculadoEm: linkedSince(horse, uid).toISOString(),
  };
}

/** Card do responsável: traz o treinador do cavalo (único).
 * @param {HorseListSource} horse Cavalo da lista.
 * @param {string} uid UID do responsável.
 * @return {Promise<GuardianHorseCard>} Card do cavalo.
 */
export async function toGuardianHorseCard(
  horse: HorseListSource,
  uid: string
): Promise<GuardianHorseCard> {
  const [trainer] = horse.treinadores;
  return {
    ...(await toHorseCardBase(horse, uid)),
    treinador: trainer ? toRefView(trainer) : null,
  };
}

/** Card do treinador: traz o proprietário do cavalo.
 * @param {HorseListSource} horse Cavalo da lista.
 * @param {string} uid UID do treinador.
 * @return {Promise<TrainerHorseCard>} Card do cavalo.
 */
export async function toTrainerHorseCard(
  horse: HorseListSource,
  uid: string
): Promise<TrainerHorseCard> {
  return {
    ...(await toHorseCardBase(horse, uid)),
    proprietario: toRefView(horse.proprietario),
  };
}
