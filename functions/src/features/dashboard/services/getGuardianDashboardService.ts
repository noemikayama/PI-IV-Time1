// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do service do dashboard do responsável.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";
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

  // Filtrar por um cavalo que não é do responsável equivale a não existir.
  const selected = filtros.cavaloId ?
    guardian.cavalos.find((horse) => horse._id.equals(filtros.cavaloId)) :
    null;
  if (filtros.cavaloId && !selected) {
    throw new AppError("not-found", "Cavalo não encontrado.");
  }

  const horseIds: ObjectId[] = selected ?
    [selected._id] :
    guardian.cavalos.map((horse) => horse._id);

  const window = resolveDashboardWindow(filtros.periodo);
  const dashboard = await aggregateHorseDashboard(
    horseIds,
    window.range,
    DASHBOARD_LIST_LIMIT
  );
  const {indicadores, ultimosTreinos, ultimosFeedbacks} = dashboard;

  return {
    tipoConta: "RESPONSAVEL",
    periodo: filtros.periodo,
    inicio: window.inicio,
    fim: window.fim,
    cavaloId: selected ? String(selected._id) : null,
    cavalos: guardian.cavalos
      .map((horse) => ({id: String(horse._id), nome: horse.nome}))
      .sort((a, b) => a.nome.localeCompare(b.nome, "pt-BR")),
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
