// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: getHorseService vira getHorseProfileService: o perfil inteiro
// (Dados, Plano atual e Avaliações) em uma consulta.
// Alteração: Conferência da conta ativa e relação TREINADOR explícita.
// Alteração: Verificação de acesso pelo helper central (horseAccess).
// Alteração: Leitura e acesso pelo getHorseForUser.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta do cavalo com a idade calculada.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import type {HorseProfile} from "../types";
import {getHorseForUser} from "./horseAccess";
import {buildHorseProfile} from "./horseProfile";

/** Retorna o perfil do cavalo para o proprietário, o atleta ou o treinador.
 * Para os demais, o cavalo é tratado como inexistente.
 * @param {AuthenticatedUser} user Usuário autenticado.
 * @param {ObjectId} id _id do cavalo.
 * @return {Promise<HorseProfile>} Perfil do cavalo.
 */
export async function getHorseProfileService(
  user: AuthenticatedUser,
  id: ObjectId
): Promise<HorseProfile> {
  const {horse} = await getHorseForUser(user, id);
  return buildHorseProfile(horse, user.uid);
}
