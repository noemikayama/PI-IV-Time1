// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Materiais atuais e mídias disponíveis no Storage dos exercícios
// do treino agendado.
// -----------------------------------------------------------------------------

import {logger} from "firebase-functions";
import type {ObjectId} from "mongodb";
import {listObjects} from "../../../shared/config/storage";
import {FILE_FORMATS} from "../../../shared/constants/files";
import {MEDIA_FIELDS, MEDIA_LIMITS} from "../constants/media";
import {findActiveExerciseExtras} from "../repositories/exerciseRepository";
import type {
  ExerciseExtras,
  ExerciseMediaContentType,
  ExerciseMediaField,
  ExerciseMediaView,
} from "../types";
import {toExerciseMediaView} from "./exerciseMediaService";

/** Extensões aceitas em cada campo de mídia ('jpg' e 'png'; 'mp4').
 * @param {ExerciseMediaField} field Campo de mídia.
 * @return {string[]} Extensões do campo.
 */
const extensionsOf = (field: ExerciseMediaField): string[] =>
  (Object.keys(MEDIA_FIELDS) as ExerciseMediaContentType[])
    .filter((type) => MEDIA_FIELDS[type] === field)
    .map((type) => FILE_FORMATS[type].extension);

/** Índice da mídia, se o caminho for um dos que o servidor gera para o
 * exercício ('<raiz>/<codigo>_<indice>.<extensão>', índice dentro do
 * limite do campo). Outro arquivo com o mesmo prefixo é ignorado.
 * @param {string} caminho Caminho listado no Storage.
 * @param {string} prefix Raiz e código ('/videos/exercicios/12_').
 * @param {ExerciseMediaField} field Campo de mídia.
 * @return {number|null} Índice, ou null se o caminho não servir.
 */
function mediaIndex(
  caminho: string,
  prefix: string,
  field: ExerciseMediaField
): number | null {
  const match = /^(\d+)\.([a-z0-9]+)$/.exec(caminho.slice(prefix.length));
  if (!match || !extensionsOf(field).includes(match[2])) return null;
  const indice = Number(match[1]);
  return indice >= 1 && indice <= MEDIA_LIMITS[field].maxFiles ?
    indice :
    null;
}

/** Busca no Storage as mídias disponíveis do exercício em um campo e
 * assina a URL de leitura de cada uma, na ordem do índice. Os caminhos são
 * os que o servidor gera pelo código, então valem também arquivos postos
 * direto no Storage. Uma falha (Storage fora do ar, por exemplo) deixa o
 * campo vazio ou pula o arquivo: as mídias são auxiliares e não podem
 * impedir o atleta de abrir o treino.
 * @param {number} codigo Código do exercício.
 * @param {ExerciseMediaField} field Campo de mídia.
 * @param {string} exercicioId _id do exercício, para o log.
 * @return {Promise<ExerciseMediaView[]>} Mídias com URL de leitura.
 */
async function availableMedias(
  codigo: number,
  field: ExerciseMediaField,
  exercicioId: string
): Promise<ExerciseMediaView[]> {
  const prefix = `${MEDIA_LIMITS[field].root}/${codigo}_`;
  const warn = (caminho: string, error: unknown) =>
    logger.warn("Mídia do exercício indisponível no Storage", {
      exercicioId,
      caminho,
      motivo: error instanceof Error ? error.message : String(error),
    });

  let caminhos: string[];
  try {
    caminhos = await listObjects(prefix);
  } catch (error) {
    warn(prefix, error);
    return [];
  }
  const ordered = caminhos
    .map((caminho) => ({caminho, indice: mediaIndex(caminho, prefix, field)}))
    .filter((item): item is {caminho: string; indice: number} =>
      item.indice !== null)
    .sort((a, b) => a.indice - b.indice || a.caminho.localeCompare(b.caminho));

  const medias = await Promise.all(
    ordered.map(async ({caminho}) => {
      try {
        return await toExerciseMediaView(caminho);
      } catch (error) {
        warn(caminho, error);
        return null;
      }
    })
  );
  return medias.filter((media): media is ExerciseMediaView => media !== null);
}

/** Lê, de uma vez, os materiais dos exercícios informados (a cópia no
 * treino não os guarda) e busca no Storage as mídias disponíveis de cada
 * um. Exercícios repetidos são lidos e buscados uma vez; inativos ou
 * inexistentes ficam fora do mapa.
 * @param {ObjectId[]} ids _id dos exercícios (podem repetir).
 * @return {Promise<Map<string, ExerciseExtras>>} Extras por _id em
 * hexadecimal.
 */
export async function loadExerciseExtras(
  ids: ObjectId[]
): Promise<Map<string, ExerciseExtras>> {
  const unique = [
    ...new Map(ids.map((id) => [id.toHexString(), id])).values(),
  ];
  const exercises = await findActiveExerciseExtras(unique);
  const entries = await Promise.all(
    exercises.map(async (exercise): Promise<[string, ExerciseExtras]> => {
      const id = exercise._id.toHexString();
      const [imagens, videos] = await Promise.all([
        availableMedias(exercise.codigo, "imagens", id),
        availableMedias(exercise.codigo, "videos", id),
      ]);
      return [id, {materiais: exercise.materiais ?? [], imagens, videos}];
    })
  );
  return new Map(entries);
}
