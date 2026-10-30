// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Gráfico de planos criados e percentual de feedbacks do
// treinador; 0% e 100% só nos extremos reais; fatias dos gráficos pelo
// maior resto.
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conversão dos números e das listas do dashboard para o app.
// -----------------------------------------------------------------------------

import {toYmd} from "../../../shared/utils/dates";
import type {FeedbackCount} from "../../training";
import type {
  CumprimentoTreinos,
  DashboardIndicadoresRow,
  FeedbackRecente,
  FeedbackRecenteRow,
  FeedbacksDados,
  FrequenciaExecucao,
  PlanosCriados,
  PlanosStatusRow,
  TreinoRecente,
  TreinoRecenteRow,
  TreinosRealizados,
} from "../types";

// Itens por lista de recentes; o restante vem em "Mostrar tudo".
export const DASHBOARD_LIST_LIMIT = 5;

/** Converte uma razão em percentual inteiro de 0 a 100. O arredondamento
 * não esconde os extremos: 199 de 200 é 99% (não 100%) e 1 de 300 é 1%
 * (não 0%).
 * @param {number} part Parte considerada.
 * @param {number} total Total da razão.
 * @return {number} Percentual arredondado (0 quando não há total).
 */
export function toPercent(part: number, total: number): number {
  if (total <= 0 || part <= 0) return 0;
  const ceiling = part < total ? 99 : 100;
  return Math.max(1, Math.min(ceiling, Math.round((part / total) * 100)));
}

/** Monta o gráfico "Treinos realizados": realizados e parciais sobre o
 * total executado. Os dois percentuais somam 100 quando há execuções.
 * @param {DashboardIndicadoresRow} row Contagens do período.
 * @return {TreinosRealizados} Dados do gráfico de setores.
 */
export function toTreinosRealizados(
  row: DashboardIndicadoresRow
): TreinosRealizados {
  const [percentualRealizados, percentualParciais] = toShares([
    row.realizados,
    row.parciais,
  ]);
  return {
    realizados: row.realizados,
    parciais: row.parciais,
    total: row.realizados + row.parciais,
    percentualRealizados,
    percentualParciais,
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

/** Divide 100 entre as fatias de um gráfico de setores pelo maior resto,
 * para que os percentuais inteiros somem exatamente 100.
 * @param {number[]} counts Quantidade de cada fatia.
 * @return {number[]} Percentual de cada fatia (zeros sem total).
 */
export function toShares(counts: number[]): number[] {
  const total = counts.reduce((sum, count) => sum + count, 0);
  if (total <= 0) return counts.map(() => 0);

  const exact = counts.map((count) => (count / total) * 100);
  const shares = exact.map(Math.floor);
  let missing = 100 - shares.reduce((sum, share) => sum + share, 0);
  // Empate no resto fica com a fatia que vem primeiro.
  const byRemainder = exact
    .map((value, index) => ({index, rest: value - shares[index]}))
    .sort((a, b) => b.rest - a.rest || a.index - b.index);
  for (const {index} of byRemainder) {
    if (missing-- <= 0) break;
    shares[index]++;
  }
  return shares;
}

/** Monta o gráfico "Planos criados" a partir das contagens por status.
 * @param {PlanosStatusRow} row Planos do período por status atual.
 * @return {PlanosCriados} Dados do gráfico de setores.
 */
export function toPlanosCriados(row: PlanosStatusRow): PlanosCriados {
  const {ativos, concluidos, cancelados, rascunhos} = row;
  const [
    percentualAtivos,
    percentualConcluidos,
    percentualCancelados,
    percentualRascunhos,
  ] = toShares([ativos, concluidos, cancelados, rascunhos]);
  return {
    total: ativos + concluidos + cancelados + rascunhos,
    ativos,
    concluidos,
    cancelados,
    rascunhos,
    percentualAtivos,
    percentualConcluidos,
    percentualCancelados,
    percentualRascunhos,
  };
}

/** Monta o card de feedbacks: executados com feedback sobre executados.
 * @param {FeedbackCount} count Contagem do período.
 * @return {FeedbacksDados} Percentual e base do cálculo.
 */
export const toFeedbacksDados = (count: FeedbackCount): FeedbacksDados => ({
  percentual: toPercent(count.withFeedback, count.executed),
  comFeedback: count.withFeedback,
  executados: count.executed,
});

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
