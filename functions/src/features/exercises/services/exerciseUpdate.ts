// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Decisão sobre o cavalo e montagem da gravação da edição do
// exercício.
// -----------------------------------------------------------------------------

import type {ObjectId, UpdateFilter} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import type {
  ExerciseDetailsInput,
  ExerciseDocument,
  ExerciseHorseRef,
  ExerciseUpdateChanges,
} from "../types";

// O que fazer com o cavalo na edição: manter, remover ou trocar pelo
// informado.
export type HorseChange<T> = "keep" | "remove" | T;

// Campos do cadastro que a edição grava. O 'satisfies' quebra a compilação
// se um campo de ExerciseDetailsInput ficar de fora ou sobrar, e a lista
// fechada impede que qualquer outro campo chegue ao $set.
const DETAIL_KEYS = {
  nome: true,
  descricao: true,
  orientacoes: true,
  duracaoPadraoMinutos: true,
  materiais: true,
} as const satisfies Record<keyof ExerciseDetailsInput, true>;

const DETAIL_FIELDS = Object.keys(DETAIL_KEYS) as
  (keyof ExerciseDetailsInput)[];

/** Decide o que fazer com o cavalo. Sem 'privacidade', tipo e cavalo não
 * mudam, e no genérico o cavalo sai. No específico, o mesmo cavalo é
 * mantido sem conferir o vínculo de novo, porque o autor continua podendo
 * editar o exercício de um cavalo com que perdeu o vínculo; um cavalo
 * diferente precisa ser conferido.
 * @param {ExerciseDocument} exercise Exercício gravado.
 * @param {ExerciseUpdateChanges} changes Alterações validadas.
 * @return {HorseChange<ObjectId>} Manter, remover ou o cavalo a conferir.
 */
export function planHorseChange(
  exercise: ExerciseDocument,
  changes: ExerciseUpdateChanges
): HorseChange<ObjectId> {
  if (changes.privacidade === undefined) return "keep";
  if (changes.privacidade === "GENERICO") return "remove";

  const {cavaloId} = changes;
  if (!cavaloId) {
    // A validação já exige o cavalo no específico; isto só protege o tipo.
    throw new AppError(
      "invalid-argument",
      "Selecione o cavalo do exercício específico."
    );
  }
  const sameHorse = exercise.privacidade === "ESPECIFICO" &&
    exercise.cavalo?._id.equals(cavaloId) === true;
  return sameHorse ? "keep" : cavaloId;
}

/** Monta a gravação da edição: $set só com os campos enviados (da lista
 * fechada), a privacidade, o cavalo novo e a data da alteração, e $unset do
 * cavalo quando o exercício vira genérico. Código, autor, datas de cadastro
 * e mídias nunca entram.
 * @param {ExerciseUpdateChanges} changes Alterações validadas.
 * @param {HorseChange<ExerciseHorseRef>} horse Manter, remover ou o cavalo
 *   novo, já conferido.
 * @param {Date} now Instante da alteração.
 * @return {UpdateFilter<ExerciseDocument>} Operação de atualização.
 */
export function buildExerciseUpdate(
  changes: ExerciseUpdateChanges,
  horse: HorseChange<ExerciseHorseRef>,
  now: Date
): UpdateFilter<ExerciseDocument> {
  const set: Partial<ExerciseDocument> = {};
  for (const field of DETAIL_FIELDS) {
    if (changes[field] !== undefined) {
      Object.assign(set, {[field]: changes[field]});
    }
  }
  if (changes.privacidade !== undefined) set.privacidade = changes.privacidade;
  if (horse !== "keep" && horse !== "remove") set.cavalo = horse;
  set.atualizadoEm = now;

  return (horse === "remove" ?
    {$set: set, $unset: {cavalo: ""}} :
    {$set: set}) as UpdateFilter<ExerciseDocument>;
}
