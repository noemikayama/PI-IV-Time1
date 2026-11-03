// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Filtro de cavalo compartilhado com o treinador e recusa do
// painel profissional, que é exclusivo dele.
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do service do dashboard do responsável.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {findGuardianHomeSource} from "../../authentication/guardian";
import {
  aggregateHorseDashboard,
} from "../repositories/dashboardRepository";
import type {DashboardFiltros, DashboardResponsavel} from "../types";
import {
  DASHBOARD_LIST_LIMIT,
  toCumprimento,
  toFeedbackRecente,
  toFrequencia,
  toTreinoRecente,
  toTreinosRealizados,
} from "./dashboardMappers";
import {resolveHorseScope, toHorseOptions} from "./dashboardHorses";
import {resolveDashboardWindow} from "./dashboardPeriod";

/** Monta o dashboard do responsável no período e no cavalo escolhidos.
 * O acesso vem da própria lista de cavalos do responsável (proprietário ou
 * atleta), então um cavalo de terceiros nunca entra nos números.
 * @param {string} uid UID do usuário.
 * @param {DashboardFiltros} filtros Período e cavalo já validados.
 * @return {Promise<DashboardResponsavel>} Dados da tela de evolução.
 */
export async function getGuardianDashboard(
  uid: string,
  filtros: DashboardFiltros
): Promise<DashboardResponsavel> {
  const guardian = await findGuardianHomeSource(uid);
  if (!guardian || guardian.situacaoCadastral !== "ATIVO") {
    throw new AppError("permission-denied", "Conta inativa ou inexistente.");
  }
  if (filtros.painelProfissional) {
    throw new AppError(
      "invalid-argument",
      "O painel profissional é exclusivo do treinador."
    );
  }

  const {selected, horseIds} = resolveHorseScope(
    guardian.cavalos,
    filtros.cavaloId
  );

  const window = resolveDashboardWindow(filtros.periodo);
  const dashboard = await aggregateHorseDashboard(
    horseIds,
    window,
    DASHBOARD_LIST_LIMIT
  );
  const {indicadores, ultimosTreinos, ultimosFeedbacks} = dashboard;

  return {
    tipoConta: "RESPONSAVEL",
    periodo: filtros.periodo,
    inicio: window.inicio,
    fim: window.fim,
    cavaloId: selected ? String(selected._id) : null,
    cavalos: toHorseOptions(guardian.cavalos),
    possuiDados: indicadores.previstos > 0 ||
      ultimosTreinos.length > 0 ||
      ultimosFeedbacks.length > 0,
    treinosRealizados: toTreinosRealizados(indicadores),
    cumprimentoTreinos: toCumprimento(indicadores),
    frequenciaExecucao: toFrequencia(indicadores),
    ultimosTreinos: ultimosTreinos.map(toTreinoRecente),
    ultimosFeedbacks: ultimosFeedbacks.map(toFeedbackRecente),
  };
}
