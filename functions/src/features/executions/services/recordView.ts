// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Resposta do treino agendado: cópia do treino, materiais e
// mídias atuais dos exercícios, execução, feedback e ações permitidas.
// -----------------------------------------------------------------------------

import {toYmd} from "../../../shared/utils/dates";
import {loadExerciseExtras} from "../../exercises";
import type {ExerciseExtras} from "../../exercises";
import {findPlanObjective} from "../../plans";
import type {TrainingRecordDocument} from "../../training";
import type {
  ExecutionView,
  FeedbackView,
  RecordExerciseView,
  RecordViewer,
  TrainingRecordView,
} from "../types";
import {
  displayedStatus,
  hasAthleteReport,
  recordPermissions,
} from "./recordRules";

/** Monta um exercício do treino: dados da cópia (o que foi planejado) e
 * materiais e mídias da versão atual, que a cópia não guarda. Exercício
 * inativo ou inexistente sai só com a cópia.
 * @param {TrainingRecordDocument} record Treino agendado.
 * @param {Map<string, ExerciseExtras>} extras Extras por _id.
 * @return {RecordExerciseView[]} Exercícios na ordem do treino.
 */
function toExerciseViews(
  record: TrainingRecordDocument,
  extras: Map<string, ExerciseExtras>
): RecordExerciseView[] {
  return record.exercicios.map((item, index) => {
    const {exercicio} = item;
    const extra = extras.get(exercicio._id.toHexString());
    const imagens = extra?.imagens ?? [];
    const videos = extra?.videos ?? [];
    return {
      posicao: index + 1,
      codigo: String(exercicio.codigo),
      nome: exercicio.nome,
      descricao: exercicio.descricao,
      orientacoes: exercicio.orientacoes,
      duracao: exercicio.duracaoPadraoMinutos,
      realizacao: item.realizacao,
      observacao: item.observacoesEspecificas ?? null,
      materiais: extra?.materiais ?? [],
      midias: {
        imagens,
        videos,
        semMidias: imagens.length === 0 && videos.length === 0,
      },
    };
  });
}

/** Relato do atleta, ou null enquanto não houver.
 * @param {TrainingRecordDocument} record Treino agendado.
 * @return {ExecutionView|null} Execução para o app.
 */
function toExecutionView(
  record: TrainingRecordDocument
): ExecutionView | null {
  if (!hasAthleteReport(record)) return null;
  const count = (realizacao: string) =>
    record.exercicios.filter((item) => item.realizacao === realizacao).length;
  return {
    // Registro antigo REALIZADO ou PARCIAL pode não ter a data.
    dataExecucao: record.dataExecucao ? toYmd(record.dataExecucao) : null,
    duracaoEfetiva: record.duracaoEfetivaMinutos ?? null,
    percepcaoDesempenho: record.percepcaoDesempenho ?? null,
    dificuldades: record.dificuldade ?? "",
    observacoes: record.observacoes ?? [],
    exerciciosRealizados: count("REALIZADO"),
    exerciciosNaoRealizados: count("NAO_REALIZADO"),
  };
}

/** Feedback do treinador, ou null enquanto não houver.
 * @param {TrainingRecordDocument} record Treino agendado.
 * @return {FeedbackView|null} Feedback para o app.
 */
function toFeedbackView(record: TrainingRecordDocument): FeedbackView | null {
  const {feedback} = record;
  if (!feedback) return null;
  return {
    data: feedback.data.toISOString(),
    comentario: feedback.comentario,
    dificuldadesIdentificadas: feedback.dificuldadesIdentificadas ?? [],
    orientacoes: feedback.orientacoes ?? [],
  };
}

/** Monta a resposta do treino agendado, usada pela consulta e pelos dois
 * envios. Objetivo do plano e extras dos exercícios são lidos em paralelo.
 * @param {TrainingRecordDocument} record Treino agendado.
 * @param {RecordViewer} viewer Relação de quem consulta com o treino.
 * @param {Date} today Hoje (meia-noite UTC).
 * @return {Promise<TrainingRecordView>} Resposta enviada ao app.
 */
export async function buildTrainingRecordView(
  record: TrainingRecordDocument,
  viewer: RecordViewer,
  today: Date
): Promise<TrainingRecordView> {
  const [objetivo, extras] = await Promise.all([
    findPlanObjective(record.plano._id),
    loadExerciseExtras(record.exercicios.map((item) => item.exercicio._id)),
  ]);
  const {treinamento} = record;
  return {
    role: viewer.role,
    registro: {
      id: record._id.toHexString(),
      codigo: record.codigo,
      status: displayedStatus(record, today),
      dataPlanejada: toYmd(record.dataPlanejada),
    },
    plano: {
      id: record.plano._id.toHexString(),
      titulo: record.plano.titulo,
      objetivo: objetivo ?? "",
    },
    treinamento: {
      codigo: String(treinamento.codigo),
      titulo: treinamento.titulo,
      descricao: treinamento.descricao ?? "",
      orientacoes: treinamento.orientacoes,
      duracaoEstimada: treinamento.duracaoEstimadaMinutos,
    },
    cavalo: {id: record.cavalo._id.toHexString(), nome: record.cavalo.nome},
    treinador: {nome: record.treinador.nome},
    atleta: record.responsavel ? {nome: record.responsavel.nome} : null,
    exercicios: toExerciseViews(record, extras),
    execucao: toExecutionView(record),
    feedback: toFeedbackView(record),
    permissoes: recordPermissions(record, viewer, today),
  };
}
