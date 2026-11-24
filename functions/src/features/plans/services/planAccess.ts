// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Acesso ao plano, status exibido e permissões, compartilhados
// pela visualização e pelo cancelamento.
// -----------------------------------------------------------------------------

import type {ClientSession} from "mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import {findActiveHorseById, relationsOf} from "../../horses";
import type {PlanDocument, PlanStatus, PlanViewerRole} from "../types";

// Quem consulta e se é o autor do plano.
export type PlanViewer = {role: PlanViewerRole; isAuthor: boolean};

export const PLAN_NOT_FOUND_MESSAGE = "Plano não encontrado.";

/** Status mostrado: um plano ATIVO vencido só é concluído no banco quando
 * outro plano é criado para o cavalo, então aparece como CONCLUIDO.
 * @param {PlanDocument} plan Status e fim do plano.
 * @param {Date} today Hoje (meia-noite UTC, como getDayStart()).
 * @return {PlanStatus} Status exibido.
 */
export const displayedStatus = (
  plan: Pick<PlanDocument, "status" | "dataFim">,
  today: Date
): PlanStatus =>
  plan.status === "ATIVO" && plan.dataFim < today ? "CONCLUIDO" : plan.status;

/** Botões da tela: só o treinador edita (plano em RASCUNHO ou ATIVO) e
 * cancela (plano ATIVO). O cancelamento confere a mesma regra.
 * @param {PlanViewerRole} role Perfil de quem consulta.
 * @param {PlanStatus} status Status exibido.
 * @return {Object} podeEditar e podeCancelar.
 */
export function planPermissions(role: PlanViewerRole, status: PlanStatus) {
  const trainer = role === "TREINADOR";
  return {
    podeEditar: trainer && (status === "RASCUNHO" || status === "ATIVO"),
    podeCancelar: trainer && status === "ATIVO",
  };
}

/** Quem acessa o plano. O treinador entra se for o autor ou o treinador
 * atual do cavalo; o responsável, se for proprietário ou atleta. O autor
 * dispensa a leitura do cavalo. Sem vínculo, 'not-found', para não revelar
 * planos de terceiros. A conta já deve ter sido conferida.
 * @param {AuthenticatedUser} user Usuário autenticado.
 * @param {PlanDocument} plan Plano lido.
 * @param {ClientSession} session Sessão da transação, se houver.
 * @return {Promise<PlanViewer>} Perfil e autoria.
 */
export async function resolvePlanViewer(
  user: AuthenticatedUser,
  plan: PlanDocument,
  session?: ClientSession
): Promise<PlanViewer> {
  const isTrainer = user.role === ROLES.trainer;
  if (isTrainer && plan.treinador._id === user.uid) {
    return {role: "TREINADOR", isAuthor: true};
  }

  const horse = await findActiveHorseById(plan.cavalo._id, session);
  const relations = horse ? relationsOf(horse, user.uid) : [];
  if (isTrainer && relations.includes("TREINADOR")) {
    return {role: "TREINADOR", isAuthor: false};
  }
  if (
    !isTrainer &&
    (relations.includes("PROPRIETARIO") || relations.includes("ATLETA"))
  ) {
    return {role: "RESPONSAVEL", isAuthor: false};
  }
  throw new AppError("not-found", PLAN_NOT_FOUND_MESSAGE);
}
