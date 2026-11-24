// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Resposta da consulta e da edição do exercício, com as URLs de
// leitura das fotos e dos vídeos.
// -----------------------------------------------------------------------------

import {toRefView} from "../../horses";
import type {
  AuthoredExercise,
  ExerciseAccess,
  ExerciseMediaView,
  ExerciseView,
} from "../types";
import {toExerciseMediaView} from "./exerciseMediaService";

type ExerciseMediaViews = {
    imagens: ExerciseMediaView[];
    videos: ExerciseMediaView[];
};

/** Monta a resposta do exercício: _id viram 'id' e datas viram ISO. O
 * cavalo só aparece no específico e para quem pode vê-lo; editar fica só
 * com o autor.
 * @param {AuthoredExercise} exercise Exercício lido do banco.
 * @param {ExerciseAccess} access Relação de quem consulta com o exercício.
 * @param {ExerciseMediaViews} media Fotos e vídeos já com URL de leitura.
 * @return {ExerciseView} Resposta enviada ao app.
 */
export function toExerciseView(
  exercise: AuthoredExercise,
  access: ExerciseAccess,
  media: ExerciseMediaViews
): ExerciseView {
  const {cavalo} = exercise;
  const showHorse = access.showHorse &&
    exercise.privacidade === "ESPECIFICO" &&
    cavalo !== undefined;
  return {
    id: exercise._id.toHexString(),
    codigo: exercise.codigo,
    nome: exercise.nome,
    descricao: exercise.descricao,
    orientacoes: exercise.orientacoes,
    duracaoPadraoMinutos: exercise.duracaoPadraoMinutos,
    materiais: exercise.materiais,
    privacidade: exercise.privacidade,
    ...(showHorse && cavalo ?
      {
        cavalo: {
          id: cavalo._id.toHexString(),
          codigo: cavalo.codigo,
          nome: cavalo.nome,
        },
      } :
      {}),
    treinador: toRefView(exercise.treinador),
    imagens: media.imagens,
    videos: media.videos,
    permissoes: {editar: access.isAuthor},
    criadoEm: exercise.criadoEm.toISOString(),
    atualizadoEm: exercise.atualizadoEm.toISOString(),
  };
}

/** Assina a URL de leitura de cada foto e vídeo, na ordem em que foram
 * anexados, e monta a resposta do exercício.
 * @param {AuthoredExercise} exercise Exercício lido do banco.
 * @param {ExerciseAccess} access Relação de quem consulta com o exercício.
 * @return {Promise<ExerciseView>} Resposta enviada ao app.
 */
export async function buildExerciseView(
  exercise: AuthoredExercise,
  access: ExerciseAccess
): Promise<ExerciseView> {
  const [imagens, videos] = await Promise.all([
    Promise.all(exercise.imagens.map(toExerciseMediaView)),
    Promise.all(exercise.videos.map(toExerciseMediaView)),
  ]);
  return toExerciseView(exercise, access, {imagens, videos});
}
