// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Agrupamento dos treinos por dia da semana e geração dos
// registros de treino do plano.
// -----------------------------------------------------------------------------

// Funções puras (sem banco), reutilizadas pela edição do plano. Datas são
// de calendário, gravadas à meia-noite UTC: o dia da semana é lido em UTC e
// nunca é deslocado por fuso.
import {ObjectId} from "mongodb";
import {addDays} from "../../../shared/utils/dates";
import type {NewTrainingRecord} from "../../training";
import {DIAS_SEMANA} from "../types";
import type {
  DiaSemana,
  PlanDocument,
  PlanningItem,
  TrainingsByDay,
} from "../types";

const DAY_MS = 86_400_000;

// Treinamento escolhido e os dias em que ele ocorre.
export type TrainingDays = {treinamentoId: ObjectId; diasSemana: DiaSemana[]};

// Data prevista e o item que a originou.
export type PlannedDate = {data: Date; item: PlanningItem};

// Campos do plano usados na geração; o responsável é o atleta do cavalo,
// omitido se não houver.
export type RecordSource = Pick<
    PlanDocument,
    "_id" | "codigo" | "titulo" | "cavalo" | "treinador" | "dataInicio" |
    "dataFim" | "planejamento"
> & {responsavel?: NewTrainingRecord["responsavel"]};

/** Dia da semana de uma data de calendário (meia-noite UTC).
 * @param {Date} date Data de calendário.
 * @return {DiaSemana} Dia da semana.
 */
const weekdayOf = (date: Date): DiaSemana =>
  DIAS_SEMANA[(date.getUTCDay() + 6) % 7];

/** Semana do plano: 1 são os 7 primeiros dias a partir de dataInicio.
 * @param {Date} start dataInicio do plano.
 * @param {Date} date Data prevista.
 * @return {number} Semana (1, 2, ...).
 */
const weekOf = (start: Date, date: Date): number =>
  Math.floor(Math.round((date.getTime() - start.getTime()) / DAY_MS) / 7) +
  1;

/** Agrupa os treinos por treinamento: um grupo por treinamento distinto,
 * com os dias em ordem de SEGUNDA a DOMINGO. A ordem dos grupos segue o
 * primeiro dia de cada um. Dias vazios (null) são ignorados.
 * @param {TrainingsByDay} byDay Treino escolhido em cada dia.
 * @return {TrainingDays[]} Treinamentos e seus dias.
 */
export function groupDaysByTraining(byDay: TrainingsByDay): TrainingDays[] {
  const groups = new Map<string, TrainingDays>();
  for (const dia of DIAS_SEMANA) {
    const id = byDay[dia];
    if (!id) continue;
    const hex = id.toHexString();
    const group = groups.get(hex);
    if (group) group.diasSemana.push(dia);
    else groups.set(hex, {treinamentoId: id, diasSemana: [dia]});
  }
  return [...groups.values()];
}

/** Datas previstas entre dataInicio e dataFim (inclusive) cujo dia da
 * semana está em um item ativo. Com 'from', começa nessa data (a edição
 * regera só os registros a partir de hoje). 'from' também precisa ser uma
 * data de calendário (meia-noite UTC, como getDayStart()).
 * @param {RecordSource} plan Período e planejamento do plano.
 * @param {Date} from Primeira data considerada, se posterior ao início.
 * @return {PlannedDate[]} Datas em ordem crescente.
 */
export function listPlannedDates(
  plan: Pick<RecordSource, "dataInicio" | "dataFim" | "planejamento">,
  from?: Date
): PlannedDate[] {
  const byDay = new Map<DiaSemana, PlanningItem>();
  for (const item of plan.planejamento) {
    if (!item.ativo) continue;
    for (const dia of item.diasSemana) byDay.set(dia, item);
  }

  const dates: PlannedDate[] = [];
  let day = from && from > plan.dataInicio ? from : plan.dataInicio;
  for (; day <= plan.dataFim; day = addDays(day, 1)) {
    const item = byDay.get(weekdayOf(day));
    if (item) dates.push({data: day, item});
  }
  return dates;
}

/** Gera os registros PLANEJADO do plano, um por data prevista. Treinamento
 * e exercícios vêm da cópia do item, nunca do treinamento atual. Os campos
 * da execução e do feedback ficam ausentes; o 'codigo' é reservado na
 * inserção.
 * @param {RecordSource} plan Plano já montado.
 * @param {Date} now Momento da geração (criadoEm/atualizadoEm).
 * @param {Date} from Primeira data considerada, se houver.
 * @return {NewTrainingRecord[]} Registros em ordem de data.
 */
export function buildTrainingRecords(
  plan: RecordSource,
  now: Date,
  from?: Date
): NewTrainingRecord[] {
  return listPlannedDates(plan, from).map(({data, item}) => {
    const {exercicios, ...treinamento} = item.treinamento;
    return {
      _id: new ObjectId(),
      plano: {_id: plan._id, codigo: plan.codigo, titulo: plan.titulo},
      itemPlanejamento: item.codigo,
      ...(plan.responsavel && {responsavel: plan.responsavel}),
      cavalo: plan.cavalo,
      treinador: plan.treinador,
      semana: weekOf(plan.dataInicio, data),
      status: "PLANEJADO",
      dataPlanejada: data,
      treinamento,
      exercicios: exercicios.map((exercicio) => ({
        exercicio,
        realizacao: "PENDENTE",
      })),
      criadoEm: now,
      atualizadoEm: now,
    };
  });
}
