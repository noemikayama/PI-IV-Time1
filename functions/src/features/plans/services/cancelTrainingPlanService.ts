// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cancelamento do plano de treinamento.
// Alteração: Resposta montada com os registros já cancelados.
// -----------------------------------------------------------------------------

import {runInTransaction} from "../../../shared/config/mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
import {getDayStart} from "../../../shared/utils/dates";
import {assertActiveAccount, updateHorseDocument} from "../../horses";
import {closePlannedRecords} from "../../training";
import {closePlan, findPlanById} from "../repositories/planRepository";
import type {
  PlanIdInput,
  PlanStatus,
  TrainingPlanDetailsResult,
} from "../types";
import {loadTrainingPlanDetails} from "./getTrainingPlanDetailsService";
import {
  displayedStatus,
  PLAN_NOT_FOUND_MESSAGE,
  planPermissions,
  resolvePlanViewer,
} from "./planAccess";

// Por que o plano não pode ser cancelado, pelo status exibido.
const NOT_CANCELABLE: Record<Exclude<PlanStatus, "ATIVO">, string> = {
  RASCUNHO: "Só planos ativos podem ser cancelados.",
  CONCLUIDO: "Este plano já terminou e não pode ser cancelado.",
  CANCELADO: "Este plano já foi cancelado.",
};

/** Cancela o plano ATIVO e ainda não vencido (DD 5.2), em uma transação:
 * o plano passa para CANCELADO; os registros PLANEJADO a partir de hoje,
 * para CANCELADO, e os de dias anteriores, para NAO_REALIZADO; o
 * planoAtual sai do cavalo. Só o treinador que vê o botão (autor do plano
 * ou treinador atual do cavalo) cancela. Devolve a tela do plano já
 * cancelado, para o app substituir o estado sem consultar de novo.
 * @param {AuthenticatedUser} user Treinador autenticado.
 * @param {PlanIdInput} input _id do plano.
 * @param {Date} now Momento do cancelamento.
 * @return {Promise<TrainingPlanDetailsResult>} Plano cancelado.
 */
export async function cancelTrainingPlanService(
  user: AuthenticatedUser,
  input: PlanIdInput,
  now = new Date()
): Promise<TrainingPlanDetailsResult> {
  await assertActiveAccount(user.uid, ROLES.trainer);
  const today = getDayStart(now);

  return runInTransaction(async (session) => {
    const plan = await findPlanById(input.planoId, session);
    if (!plan) throw new AppError("not-found", PLAN_NOT_FOUND_MESSAGE);

    const viewer = await resolvePlanViewer(user, plan, session);
    const status = displayedStatus(plan, today);
    if (!planPermissions(viewer.role, status).podeCancelar) {
      throw new AppError(
        "failed-precondition",
        NOT_CANCELABLE[status as Exclude<PlanStatus, "ATIVO">]
      );
    }

    if (!(await closePlan(plan._id, "CANCELADO", session))) {
      throw new AppError("failed-precondition", NOT_CANCELABLE.CANCELADO);
    }
    await closePlannedRecords(plan._id, session, today);
    await updateHorseDocument(
      plan.cavalo._id,
      {$unset: {planoAtual: ""}, $set: {atualizadoEm: new Date()}},
      session
    );

    return loadTrainingPlanDetails(
      {...plan, status: "CANCELADO", atualizadoEm: now},
      viewer,
      today,
      session
    );
  });
}
