// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conversão dos números e das listas do dashboard para o app.
// -----------------------------------------------------------------------------

import {toYmd} from "../../../shared/utils/dates";
import type {
  CumprimentoTreinos,
  DashboardIndicadoresRow,
  FeedbackRecente,
  FeedbackRecenteRow,
  FrequenciaExecucao,
  TreinoRecente,
  TreinoRecenteRow,
  TreinosRealizados,
} from "../types";

// Itens por lista de recentes; o restante vem em "Mostrar tudo".
export const DASHBOARD_LIST_LIMIT = 5;

/** Converte uma razão em percentual inteiro de 0 a 100.
 * @param {number} part Parte considerada.
 * @param {number} total Total da razão.
 * @return {number} Percentual arredondado (0 quando não há total).
 */
export function toPercent(part: number, total: number): number {
  if (total <= 0) return 0;
  return Math.min(100, Math.round((part / total) * 100));
}

/** Monta o gráfico "Treinos realizados": realizados e parciais sobre o
 * total executado. Os dois percentuais somam 100 quando há execuções.
 * @param {DashboardIndicadoresRow} row Contagens do período.
 * @return {TreinosRealizados} Dados do gráfico de setores.
 */
export function toTreinosRealizados(
  row: DashboardIndicadoresRow
): TreinosRealizados {
  const total = row.realizados + row.parciais;
  const percentualRealizados = toPercent(row.realizados, total);
  return {
    realizados: row.realizados,
    parciais: row.parciais,
    total,
    percentualRealizados,
    percentualParciais: total > 0 ? 100 - percentualRealizados : 0,
  };
}

/** Monta o cumprimento: média das razões entre duração efetiva e estimada
 * dos treinos executados que têm as duas durações.
 * @param {DashboardIndicadoresRow} row Contagens do período.
 * @return {CumprimentoTreinos} Percentual e base do cálculo.
 */
export function toCumprimento(
  row: DashboardIndicadoresRow
): CumprimentoTreinos {
  return {
    percentual: toPercent(row.somaCumprimento, row.treinosConsiderados),
    treinosConsiderados: row.treinosConsiderados,
  };
}

/** Monta a frequência: executados sobre os previstos do período.
 * @param {DashboardIndicadoresRow} row Contagens do período.
 * @return {FrequenciaExecucao} Percentual e base do cálculo.
 */
export function toFrequencia(
  row: DashboardIndicadoresRow
): FrequenciaExecucao {
  const executados = row.realizados + row.parciais;
  return {
    percentual: toPercent(executados, row.previstos),
    executados,
    previstos: row.previstos,
  };
}

export const toTreinoRecente = (row: TreinoRecenteRow): TreinoRecente => ({
  registroId: String(row._id),
  nomeTreino: row.treinamento?.titulo ?? "",
  nomeCavalo: row.cavalo?.nome ?? "",
  nomePlano: row.plano?.titulo ?? "",
  data: toYmd(row.dataExecucao),
});

export const toFeedbackRecente = (
  row: FeedbackRecenteRow
): FeedbackRecente => ({
  registroId: String(row._id),
  nomeTreino: row.treinamento?.titulo ?? "",
  nomePlano: row.plano?.titulo ?? "",
  data: row.feedback.data.toISOString(),
});
