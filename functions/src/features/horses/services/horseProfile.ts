// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: TrainingRecordSummary no lugar de DayTrainingRecord.
//
// Data: 04/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Treino do dia CONCLUIDO só quando REALIZADO ou PARCIAL (mesma
// regra do dashboard); nome da pessoa do card null quando ausente.
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Montagem do perfil do cavalo (cabeçalho, Dados, Plano atual e
// Avaliações) em uma resposta, no lugar de toHorseView, do plano atual e
// do histórico de avaliações separados.
// -----------------------------------------------------------------------------

import {getPeriods} from "../../../shared/utils/dates";
import {EXECUTED_STATUSES, findDayRecordsByHorsePlan} from "../../training";
import type {TrainingRecordSummary} from "../../training";
import type {
  CurrentPlanRef,
  HorseDayTrainingState,
  HorseDocument,
  HorseEvaluationCard,
  HorseProfile,
  HorseProfilePermissions,
  HorseRelation,
} from "../types";
import {HORSE_RULES, isAllowed, relationsOf} from "./horseAccess";
import {calculateHorseAge} from "./horseAge";
import {toHorseImageView} from "./horseImageService";
import {toRefView} from "./horseMappers";

/** Permissões exibidas no perfil, pelas mesmas regras das callables. O
 * atleta (inclusive quando também é proprietário) inicia o treino; os
 * demais apenas o visualizam.
 * @param {HorseRelation[]} relations Relação de quem consulta.
 * @return {HorseProfilePermissions} Ações disponíveis.
 */
function toPermissions(relations: HorseRelation[]): HorseProfilePermissions {
  return {
    editar: isAllowed(relations, HORSE_RULES.editar),
    adicionarSaude: isAllowed(relations, HORSE_RULES.adicionarSaude),
    excluir: isAllowed(relations, HORSE_RULES.excluir),
    gerenciarVinculos: isAllowed(relations, HORSE_RULES.gerenciarVinculos),
    criarAvaliacao: isAllowed(relations, HORSE_RULES.criarAvaliacao),
    acaoTreino: relations.includes("ATLETA") ? "INICIAR" : "VER",
  };
}

/** Se o treino foi feito (REALIZADO ou PARCIAL), como no dashboard.
 * @param {TrainingRecordSummary} record Registro do dia.
 * @return {boolean} Se o treino está concluído.
 */
const isDone = (record: TrainingRecordSummary): boolean =>
  EXECUTED_STATUSES.includes(record.status);

/** Treino de hoje do plano. Havendo mais de um registro no dia, mostra o
 * primeiro ainda pendente; sem pendentes, o último concluído.
 * @param {TrainingRecordSummary[]} records Registros do dia, por criação.
 * @param {CurrentPlanRef} plan Plano ATIVO do cavalo.
 * @param {HorseRelation[]} relations Relação de quem consulta.
 * @return {HorseDayTrainingState} Situação explícita e o card.
 */
function toDayTraining(
  records: TrainingRecordSummary[],
  plan: CurrentPlanRef,
  relations: HorseRelation[]
): HorseDayTrainingState {
  const record =
    records.find((item) => !isDone(item)) ?? records[records.length - 1];
  if (!record) return {situacao: "SEM_TREINO", treino: null};

  // O registro grava o atleta como responsável.
  const pessoa = relations.includes("TREINADOR") ?
    {papel: "ATLETA" as const, nome: record.responsavel?.nome ?? null} :
    {papel: "TREINADOR" as const, nome: record.treinador?.nome ?? null};

  return {
    situacao: isDone(record) ? "CONCLUIDO" : "PENDENTE",
    treino: {
      registroId: String(record._id),
      nomeTreino: record.treinamento?.titulo ?? "",
      nomePlano: record.plano?.titulo ?? plan.titulo,
      duracaoMinutos: record.treinamento?.duracaoEstimadaMinutos ?? 0,
      pessoa,
      status: record.status,
    },
  };
}

/** Cards das avaliações em ordem cronológica decrescente (RF06003). A ordem
 * já é gravada decrescente; a ordenação aqui só a garante.
 * @param {HorseDocument} horse Documento do cavalo.
 * @return {HorseEvaluationCard[]} Cards da aba "Avaliações".
 */
function toEvaluationCards(horse: HorseDocument): HorseEvaluationCard[] {
  return [...horse.avaliacoes]
    .sort((a, b) => b.data.localeCompare(a.data) || b.codigo - a.codigo)
    .map((avaliacao) => ({
      id: String(avaliacao._id),
      codigo: avaliacao.codigo,
      data: avaliacao.data,
      treinador: toRefView(avaliacao.treinador),
    }));
}

/** Monta o perfil do cavalo para quem consulta. Além do documento, lê só os
 * registros de hoje do plano ATIVO, em paralelo com as URLs das imagens.
 * O acesso já deve ter sido conferido por quem chama.
 * @param {HorseDocument} horse Documento do cavalo (ativo).
 * @param {string} uid UID de quem consulta.
 * @return {Promise<HorseProfile>} Perfil no formato do app.
 */
export async function buildHorseProfile(
  horse: HorseDocument,
  uid: string
): Promise<HorseProfile> {
  const relations = relationsOf(horse, uid);
  const plan = horse.planoAtual;

  const [imagens, records] = await Promise.all([
    Promise.all(horse.imagens.map(toHorseImageView)),
    plan ?
      findDayRecordsByHorsePlan(horse._id, plan._id, getPeriods().day) :
      Promise.resolve([] as TrainingRecordSummary[]),
  ]);

  const [trainer] = horse.treinadores;

  return {
    id: horse._id.toHexString(),
    // O microchip só aparece para o proprietário.
    codigo: relations.includes("PROPRIETARIO") ? horse.codigo : null,
    nome: horse.nome,
    imagens,
    dataNascimento: horse.dataNascimento,
    idade: calculateHorseAge(horse.dataNascimento),
    raca: horse.raca,
    pelagem: horse.pelagem,
    sexo: horse.sexo,
    modalidade: horse.modalidade ? toRefView(horse.modalidade) : null,
    limitacoesFisicas: horse.limitacoesFisicas,
    observacoesSaude: horse.observacoesSaude,
    historicoLesoes: horse.historicoLesoes,
    proprietario: toRefView(horse.proprietario),
    atleta: horse.atleta ? toRefView(horse.atleta) : null,
    treinador: trainer ? toRefView(trainer) : null,
    responsabilidades: relations,
    permissoes: toPermissions(relations),
    planoAtual: plan ? {
      id: plan._id.toHexString(),
      codigo: plan.codigo,
      titulo: plan.titulo,
      dataInicio: plan.dataInicio,
      dataFim: plan.dataFim,
      treinoDoDia: toDayTraining(records, plan, relations),
    } : null,
    avaliacoes: toEvaluationCards(horse),
    atualizadoEm: horse.atualizadoEm.toISOString(),
  };
}
