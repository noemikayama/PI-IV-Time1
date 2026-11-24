// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do service do dashboard do treinador.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {findTrainerHomeSource} from "../../authentication/trainer";
import type {TrainerHomeSource} from "../../authentication/trainer";
import {countActiveExercisesByTrainer} from "../../exercises";
import {countTrainerFeedbacks} from "../../training";
import {
  aggregateHorseDashboard,
  countTrainerEvaluations,
  countTrainerPlansByStatus,
} from "../repositories/dashboardRepository";
import type {
  DashboardFiltros,
  DashboardTreinador,
  DashboardTreinadorCavalos,
  DashboardTreinadorProfissional,
  DashboardWindow,
} from "../types";
import {
  DASHBOARD_LIST_LIMIT,
  toCumprimento,
  toFeedbacksDados,
  toFrequencia,
  toPlanosCriados,
  toTreinoRecente,
  toTreinosRealizados,
} from "./dashboardMappers";
import {resolveHorseScope, toHorseOptions} from "./dashboardHorses";
import {resolveDashboardWindow} from "./dashboardPeriod";

/** Visão dos cavalos: os mesmos indicadores do responsável, sobre os
 * cavalos que o treinador acompanha. Entram todos os registros desses
 * cavalos, inclusive de planos de outro treinador (DD 5.2: o treinador
 * acessa os registros dos cavalos que acompanha).
 * @param {TrainerHomeSource} trainer Treinador já validado.
 * @param {DashboardFiltros} filtros Período e cavalo.
 * @param {DashboardWindow} window Janela do período.
 * @return {Promise<DashboardTreinadorCavalos>} Dados da visão.
 */
async function getHorsesView(
  trainer: TrainerHomeSource,
  filtros: DashboardFiltros,
  window: DashboardWindow
): Promise<DashboardTreinadorCavalos> {
  const {selected, horseIds} = resolveHorseScope(
    trainer.cavalos,
    filtros.cavaloId
  );

  // Um item além do exibido indica se o "Mostrar tudo" tem o que mostrar.
  const {indicadores, ultimosTreinos} = await aggregateHorseDashboard(
    horseIds,
    window,
    DASHBOARD_LIST_LIMIT + 1,
    false
  );

  return {
    tipoConta: "TREINADOR",
    painelProfissional: false,
    periodo: filtros.periodo,
    inicio: window.inicio,
    fim: window.fim,
    cavaloId: selected ? String(selected._id) : null,
    cavalos: toHorseOptions(trainer.cavalos),
    possuiDados: indicadores.previstos > 0 || ultimosTreinos.length > 0,
    treinosRealizados: toTreinosRealizados(indicadores),
    cumprimentoTreinos: toCumprimento(indicadores),
    frequenciaExecucao: toFrequencia(indicadores),
    ultimosTreinos: ultimosTreinos
      .slice(0, DASHBOARD_LIST_LIMIT)
      .map(toTreinoRecente),
    possuiMaisTreinos: ultimosTreinos.length > DASHBOARD_LIST_LIMIT,
  };
}

/** Painel profissional: produção do próprio treinador no período. Tudo é
 * filtrado pela autoria ('treinador._id'), então só entram dados dele.
 * @param {string} uid UID do treinador.
 * @param {TrainerHomeSource} trainer Treinador já validado.
 * @param {DashboardFiltros} filtros Período.
 * @param {DashboardWindow} window Janela do período.
 * @return {Promise<DashboardTreinadorProfissional>} Dados da visão.
 */
async function getProfessionalView(
  uid: string,
  trainer: TrainerHomeSource,
  filtros: DashboardFiltros,
  window: DashboardWindow
): Promise<DashboardTreinadorProfissional> {
  const [planos, feedbacks, avaliacoes, exercicios] = await Promise.all([
    countTrainerPlansByStatus(uid, window.instants),
    countTrainerFeedbacks(uid, window.range),
    countTrainerEvaluations(uid, window.range),
    countActiveExercisesByTrainer(uid, window.instants),
  ]);

  return {
    tipoConta: "TREINADOR",
    painelProfissional: true,
    periodo: filtros.periodo,
    inicio: window.inicio,
    fim: window.fim,
    planosCriados: toPlanosCriados(planos),
    feedbacksDados: toFeedbacksDados(feedbacks),
    clientesVinculados: trainer.clientes.length,
    cavalosVinculados: trainer.cavalos.length,
    avaliacoesFeitas: avaliacoes,
    exerciciosCriados: exercicios,
  };
}

/** Monta o dashboard do treinador. O botão "Painel profissional" escolhe a
 * visão: desativado, a evolução dos cavalos; ativado, a produção dele.
 * @param {string} uid UID do usuário.
 * @param {DashboardFiltros} filtros Filtros já validados.
 * @return {Promise<DashboardTreinador>} Dados da tela de evolução.
 */
export async function getTrainerDashboard(
  uid: string,
  filtros: DashboardFiltros
): Promise<DashboardTreinador> {
  const trainer = await findTrainerHomeSource(uid);
  if (!trainer || trainer.situacaoProfissional === "INATIVO") {
    throw new AppError("permission-denied", "Conta inativa ou inexistente.");
  }
  // O painel profissional mostra a produção do treinador como um todo.
  if (filtros.painelProfissional && filtros.cavaloId) {
    throw new AppError(
      "invalid-argument",
      "O painel profissional não filtra por cavalo."
    );
  }

  const window = resolveDashboardWindow(filtros.periodo);
  return filtros.painelProfissional ?
    getProfessionalView(uid, trainer, filtros, window) :
    getHorsesView(trainer, filtros, window);
}
