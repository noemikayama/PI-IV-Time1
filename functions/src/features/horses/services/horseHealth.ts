// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Inclusões e remoções nas listas de saúde e de lesões.
// Alteração: Renomeado de applyHealthChanges.ts; recebe as regras de
// ordenação e de data das lesões, antes em validateHorse.ts.
// -----------------------------------------------------------------------------

// Regras de domínio das listas de saúde e de lesões do cavalo, aplicadas
// pelos services sobre o documento (cadastro, edição e inclusão).
import {AppError} from "../../../shared/errors/AppError";
import {MAX_INJURIES, MAX_LIST_ITEMS} from "../constants/health";
import type {
  HorseHealthChanges,
  HorseHealthLists,
  InjuryRecord,
  ListChanges,
} from "../types";

/** Ordena as lesões da mais recente à mais antiga (ordem gravada).
 * @param {InjuryRecord[]} injuries Lesões.
 * @return {InjuryRecord[]} Lesões ordenadas.
 */
export function sortInjuries(injuries: InjuryRecord[]): InjuryRecord[] {
  return [...injuries].sort((a, b) => b.data.localeCompare(a.data));
}

/** Garante que nenhuma lesão seja anterior ao nascimento.
 * @param {string} dataNascimento Data de nascimento.
 * @param {InjuryRecord[]} lesoes Lesões a conferir.
 */
export function assertInjuriesAfterBirth(
  dataNascimento: string,
  lesoes: InjuryRecord[]
): void {
  if (lesoes.some((lesao) => lesao.data < dataNascimento)) {
    throw new AppError(
      "invalid-argument",
      "A data da lesão não pode ser anterior ao nascimento."
    );
  }
}

const normalize = (text: string) => text.toLocaleLowerCase("pt-BR");

const textKey = (text: string) => normalize(text);

const injuryKey = (injury: InjuryRecord) =>
  [injury.data, injury.descricao, injury.prescricao ?? ""]
    .map(normalize)
    .join("|");

/** Remove e acrescenta itens sobre a lista gravada, mantendo os demais na
 * ordem atual. Item a remover precisa existir; item a incluir não pode
 * estar gravado nem repetido.
 * @param {Array} current Lista gravada.
 * @param {ListChanges} changes Itens a incluir e a remover.
 * @param {Function} keyOf Chave de comparação (sem diferença de caixa).
 * @param {string} label Nome da lista usado nas mensagens.
 * @param {number} max Quantidade máxima de itens.
 * @return {Array} Lista final.
 */
function applyListChanges<T>(
  current: T[],
  changes: ListChanges<T>,
  keyOf: (item: T) => string,
  label: string,
  max: number
): T[] {
  const currentKeys = new Set(current.map(keyOf));
  const removed = new Set<string>();
  for (const item of changes.remover) {
    const key = keyOf(item);
    if (!currentKeys.has(key)) {
      throw new AppError("not-found", `${label}: item não encontrado.`);
    }
    removed.add(key);
  }

  const kept = current.filter((item) => !removed.has(keyOf(item)));
  const keptKeys = new Set(kept.map(keyOf));
  const addedKeys = new Set<string>();
  for (const item of changes.adicionar) {
    const key = keyOf(item);
    if (removed.has(key)) {
      throw new AppError(
        "invalid-argument",
        `${label}: o mesmo item não pode ser incluído e removido.`
      );
    }
    if (keptKeys.has(key)) {
      throw new AppError("invalid-argument", `${label}: item já cadastrado.`);
    }
    if (addedKeys.has(key)) {
      throw new AppError(
        "invalid-argument",
        `${label}: item repetido na lista.`
      );
    }
    addedKeys.add(key);
  }

  const result = [...kept, ...changes.adicionar];
  if (result.length > max) {
    throw new AppError(
      "invalid-argument",
      `${label}: limite de ${max} itens atingido.`
    );
  }
  return result;
}

/** Calcula as listas finais das que foram alteradas. Deve ser chamada
 * dentro da transação, sobre o documento lido nela: se outra edição
 * gravar o cavalo antes, a transação é repetida com a lista nova.
 * @param {HorseHealthLists} current Listas gravadas.
 * @param {Partial<HorseHealthChanges>} changes Alterações validadas.
 * @return {Partial<HorseHealthLists>} Listas finais alteradas.
 */
export function applyHealthChanges(
  current: HorseHealthLists,
  changes: Partial<HorseHealthChanges>
): Partial<HorseHealthLists> {
  const result: Partial<HorseHealthLists> = {};
  if (changes.limitacoesFisicas) {
    result.limitacoesFisicas = applyListChanges(
      current.limitacoesFisicas,
      changes.limitacoesFisicas,
      textKey,
      "Limitações físicas",
      MAX_LIST_ITEMS
    );
  }
  if (changes.observacoesSaude) {
    result.observacoesSaude = applyListChanges(
      current.observacoesSaude,
      changes.observacoesSaude,
      textKey,
      "Observações de saúde",
      MAX_LIST_ITEMS
    );
  }
  if (changes.historicoLesoes) {
    result.historicoLesoes = sortInjuries(
      applyListChanges(
        current.historicoLesoes,
        changes.historicoLesoes,
        injuryKey,
        "Histórico de lesões",
        MAX_INJURIES
      )
    );
  }
  return result;
}
