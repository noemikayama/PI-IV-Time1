// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Consulta do exercício pelo autor e por quem tem vínculo com um
// cavalo dele.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import {assertActiveAccount} from "../../horses";
import {
  findActiveExerciseByCode,
  findActiveExerciseById,
} from "../repositories/exerciseRepository";
import type {ExerciseDocument, ExerciseLookup, ExerciseView} from "../types";
import {hasAuthor, resolveExerciseAccess} from "./exerciseAccess";
import {buildExerciseView} from "./exerciseView";

/** Lê o exercício ativo pelo identificador da consulta.
 * @param {ExerciseLookup} lookup 'id' ou 'codigo' do exercício.
 * @return {Promise<ExerciseDocument|null>} Exercício, ou null.
 */
function findLookedUpExercise(
  lookup: ExerciseLookup
): Promise<ExerciseDocument | null> {
  return "id" in lookup ?
    findActiveExerciseById(lookup.id) :
    findActiveExerciseByCode(lookup.codigo);
}

/** Consulta o exercício completo, com fotos e vídeos. Inexistente,
 * excluído, da plataforma ou sem acesso recebem a mesma resposta, para não
 * revelar exercícios de terceiros.
 * @param {AuthenticatedUser} user Usuário autenticado (uid e papel).
 * @param {ExerciseLookup} lookup 'id' ou 'codigo' do exercício.
 * @return {Promise<ExerciseView>} Exercício, como o app o recebe.
 */
export async function getExerciseService(
  user: AuthenticatedUser,
  lookup: ExerciseLookup
): Promise<ExerciseView> {
  // Conta e exercício são lidos juntos. Conta inativa sempre prevalece,
  // porque a leitura do exercício nunca falha (devolve null).
  const [exercise] = await Promise.all([
    findLookedUpExercise(lookup),
    assertActiveAccount(user.uid, user.role),
  ]);
  const notFound = () =>
    new AppError("not-found", "Exercício não encontrado.");
  if (!exercise || !hasAuthor(exercise)) throw notFound();

  const access = await resolveExerciseAccess(exercise, user.uid);
  if (!access) throw notFound();
  return buildExerciseView(exercise, access);
}
