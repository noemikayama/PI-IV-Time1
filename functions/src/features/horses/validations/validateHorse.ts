// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: parseMicrochip exportado, para o callable validateMicrochip.
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Microchip editável e modalidade obrigatória.
// Alteração: Listas de saúde e de lesões editadas por inclusão e remoção.
// Alteração: Validação da inclusão de um item por proprietário, atleta ou
// treinador.
// Alteração: Ordenação e data das lesões movidas para services/horseHealth.ts;
// este arquivo só valida a entrada.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do cadastro, da edição e da consulta de cavalos.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {getTodayYmd, isValidYmd} from "../../../shared/utils/dates";
import {asRecord, assertAllowedFields} from "../../authentication/shared";
import {
  MAX_INJURIES,
  MAX_ITEM_LENGTH,
  MAX_LIST_ITEMS,
} from "../constants/health";
import type {
  HorseFieldsInput,
  HorseHealthChanges,
  HorseHealthEntryInput,
  HorseHealthLists,
  HorseRegistrationInput,
  HorseResponsibility,
  HorseSex,
  HorseUpdateInput,
  InjuryRecord,
  ListChanges,
} from "../types";

const MICROCHIP_PATTERN = /^\d{15}$/;
const SEXES: readonly HorseSex[] = ["MACHO", "FEMEA"];
const RESPONSIBILITIES: readonly HorseResponsibility[] = [
  "PROPRIETARIO",
  "ATLETA",
];
const MAX_AGE_YEARS = 50;

/** Cria um erro de argumento inválido com a mensagem informada.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro de argumento inválido.
 */
function invalid(message: string): AppError {
  return new AppError("invalid-argument", message);
}

/** Valida um texto obrigatório e remove espaços nas pontas.
 * @param {unknown} value Valor recebido.
 * @param {string} label Nome do campo usado na mensagem.
 * @param {number} min Tamanho mínimo.
 * @param {number} max Tamanho máximo.
 * @return {string} Texto normalizado.
 */
function parseText(
  value: unknown,
  label: string,
  min: number,
  max: number
): string {
  const text = typeof value === "string" ? value.trim() : "";
  if (text.length < min || text.length > max) {
    throw invalid(`${label} deve ter entre ${min} e ${max} caracteres.`);
  }
  return text;
}

/** Valida um item de uma lista de textos (sem item vazio).
 * @param {unknown} value Valor recebido.
 * @param {string} label Nome da lista usado na mensagem.
 * @return {string} Item normalizado.
 */
function parseTextItem(value: unknown, label: string): string {
  return parseText(
    value,
    `Cada item de ${label.toLowerCase()}`,
    1,
    MAX_ITEM_LENGTH
  );
}

/** Valida uma lista de até 'max' itens com o parser informado.
 * @param {unknown} value Valor recebido.
 * @param {string} label Nome da lista usado na mensagem.
 * @param {number} max Quantidade máxima de itens.
 * @param {Function} parseItem Validação de cada item.
 * @return {Array} Itens normalizados.
 */
function parseList<T>(
  value: unknown,
  label: string,
  max: number,
  parseItem: (item: unknown) => T
): T[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > max) {
    throw invalid(`${label}: informe no máximo ${max} itens.`);
  }
  return value.map(parseItem);
}

/** Valida uma data AAAA-MM-DD que não pode estar no futuro.
 * @param {unknown} value Valor recebido.
 * @param {string} label Nome do campo usado na mensagem.
 * @return {string} Data validada.
 */
function parsePastDate(value: unknown, label: string): string {
  if (typeof value !== "string" || !isValidYmd(value)) {
    throw invalid(`${label} inválida. Use o formato AAAA-MM-DD.`);
  }
  if (value > getTodayYmd()) {
    throw invalid(`${label} não pode estar no futuro.`);
  }
  return value;
}

/** Valida a data de nascimento (não futura e com idade plausível).
 * @param {unknown} value Valor recebido.
 * @return {string} Data validada.
 */
function parseBirthDate(value: unknown): string {
  const date = parsePastDate(value, "Data de nascimento");
  const today = getTodayYmd();
  const oldest = `${Number(today.slice(0, 4)) - MAX_AGE_YEARS}${
    today.slice(4)
  }`;
  if (date < oldest) {
    throw invalid(
      `A data de nascimento indica mais de ${MAX_AGE_YEARS} anos.`
    );
  }
  return date;
}

/** Valida o sexo do cavalo.
 * @param {unknown} value Valor recebido.
 * @return {HorseSex} Sexo validado.
 */
function parseSexo(value: unknown): HorseSex {
  if (!SEXES.includes(value as HorseSex)) {
    throw invalid("Sexo inválido. Use MACHO ou FEMEA.");
  }
  return value as HorseSex;
}

/** Valida o _id (hexadecimal) de um documento.
 * @param {unknown} value Valor recebido.
 * @param {string} message Mensagem usada se o valor for inválido.
 * @return {ObjectId} _id convertido.
 */
function parseObjectId(value: unknown, message: string): ObjectId {
  if (typeof value !== "string" || !/^[0-9a-f]{24}$/i.test(value)) {
    throw invalid(message);
  }
  return new ObjectId(value);
}

/** Valida a modalidade, obrigatória no cadastro e na edição.
 * @param {unknown} value Valor recebido.
 * @return {ObjectId} _id da modalidade.
 */
function parseModalidadeId(value: unknown): ObjectId {
  if (value === undefined || value === null) {
    throw invalid("Informe a modalidade do cavalo.");
  }
  return parseObjectId(value, "Modalidade inválida.");
}

/** Valida um registro de lesão; a prescrição médica é opcional.
 * @param {unknown} item Valor recebido.
 * @return {InjuryRecord} Lesão normalizada.
 */
function parseInjury(item: unknown): InjuryRecord {
  const {data, descricao, prescricao} = asRecord(item, "Lesão inválida.");
  const injury: InjuryRecord = {
    data: parsePastDate(data, "Data da lesão"),
    descricao: parseText(
      descricao,
      "A descrição da lesão",
      1,
      MAX_ITEM_LENGTH
    ),
  };
  // Texto vazio equivale a não informar a prescrição.
  if (typeof prescricao === "string" && prescricao.trim() === "") {
    return injury;
  }
  if (prescricao !== undefined && prescricao !== null) {
    injury.prescricao = parseText(
      prescricao,
      "A prescrição médica",
      1,
      MAX_ITEM_LENGTH
    );
  }
  return injury;
}

/** Valida a relação de quem cadastra com o cavalo.
 * @param {unknown} value Valor recebido.
 * @return {HorseResponsibility[]} Responsabilidades sem repetição.
 */
function parseResponsabilidades(value: unknown): HorseResponsibility[] {
  if (
    !Array.isArray(value) ||
    value.length === 0 ||
    value.some((item) => !RESPONSIBILITIES.includes(item))
  ) {
    throw invalid(
      "Informe a relação com o cavalo: PROPRIETARIO e/ou ATLETA."
    );
  }
  return RESPONSIBILITIES.filter((item) => value.includes(item));
}

/** Valida o microchip: exatamente 15 dígitos numéricos.
 * @param {unknown} value Valor recebido.
 * @return {string} Código do microchip.
 */
export function parseMicrochip(value: unknown): string {
  const codigo = typeof value === "string" ? value.trim() : "";
  if (!MICROCHIP_PATTERN.test(codigo)) {
    throw invalid("O microchip deve ter exatamente 15 dígitos numéricos.");
  }
  return codigo;
}

// Um parser por campo simples; compartilhado entre cadastro e edição.
const FIELD_PARSERS: {
  [K in keyof HorseFieldsInput]: (value: unknown) => HorseFieldsInput[K];
} = {
  codigo: parseMicrochip,
  nome: (value) => parseText(value, "O nome", 2, 80),
  dataNascimento: parseBirthDate,
  raca: (value) => parseText(value, "A raça", 1, 60),
  pelagem: (value) => parseText(value, "A pelagem", 1, 60),
  sexo: parseSexo,
  modalidadeId: parseModalidadeId,
};

const FIELDS = Object.keys(FIELD_PARSERS) as (keyof HorseFieldsInput)[];

// Rótulo, limite e validação de item de cada lista de saúde.
const LIST_RULES: {
  [K in keyof HorseHealthLists]: {
    label: string;
    max: number;
    parseItem: (item: unknown) => HorseHealthLists[K][number];
  };
} = {
  limitacoesFisicas: {
    label: "Limitações físicas",
    max: MAX_LIST_ITEMS,
    parseItem: (item) => parseTextItem(item, "Limitações físicas"),
  },
  observacoesSaude: {
    label: "Observações de saúde",
    max: MAX_LIST_ITEMS,
    parseItem: (item) => parseTextItem(item, "Observações de saúde"),
  },
  historicoLesoes: {
    label: "Histórico de lesões",
    max: MAX_INJURIES,
    parseItem: parseInjury,
  },
};

const LISTS = Object.keys(LIST_RULES) as (keyof HorseHealthLists)[];

/** Valida a lista completa enviada no cadastro.
 * @param {string} field Nome da lista.
 * @param {unknown} value Valor recebido.
 * @return {Array} Itens normalizados.
 */
function parseFullList<K extends keyof HorseHealthLists>(
  field: K,
  value: unknown
): HorseHealthLists[K] {
  const {label, max, parseItem} = LIST_RULES[field];
  return parseList(value, label, max, parseItem) as HorseHealthLists[K];
}

/** Valida as inclusões e remoções de uma lista na edição. A existência e a
 * repetição dos itens são conferidas no service, contra a lista gravada.
 * @param {string} field Nome da lista.
 * @param {unknown} value Valor recebido.
 * @return {Object|undefined} Operações, ou undefined se não houver nenhuma.
 */
function parseListChanges<K extends keyof HorseHealthLists>(
  field: K,
  value: unknown
): HorseHealthChanges[K] | undefined {
  const {label, max, parseItem} = LIST_RULES[field];
  const record = asRecord(value, `${label}: use 'adicionar' e 'remover'.`);
  assertAllowedFields(record, ["adicionar", "remover"]);
  const changes: ListChanges<HorseHealthLists[K][number]> = {
    adicionar: parseList(record.adicionar, label, max, parseItem),
    remover: parseList(record.remover, label, max, parseItem),
  };
  if (changes.adicionar.length === 0 && changes.remover.length === 0) {
    return undefined;
  }
  return changes as HorseHealthChanges[K];
}

/** Valida e normaliza os dados do cadastro de cavalo.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {HorseRegistrationInput} Dados validados e normalizados.
 */
export function validateHorseRegistration(
  data: unknown
): HorseRegistrationInput {
  const record = asRecord(data);
  const fields = Object.fromEntries(
    FIELDS.map((field) => [field, FIELD_PARSERS[field](record[field])])
  ) as HorseFieldsInput;
  const lists = Object.fromEntries(
    LISTS.map((field) => [field, parseFullList(field, record[field])])
  ) as HorseHealthLists;

  return {
    ...fields,
    ...lists,
    responsabilidades: parseResponsabilidades(record.responsabilidades),
  };
}

/** Valida a edição: 'id' e apenas os campos enviados. As listas vêm como
 * { adicionar, remover }.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {HorseUpdateInput} Alterações validadas.
 */
export function validateHorseUpdate(data: unknown): HorseUpdateInput {
  const record = asRecord(data);
  const id = parseObjectId(record.id, "Cavalo inválido.");
  const changes: HorseUpdateInput["changes"] = {};

  for (const field of FIELDS) {
    if (record[field] === undefined) continue;
    Object.assign(changes, {[field]: FIELD_PARSERS[field](record[field])});
  }
  for (const field of LISTS) {
    if (record[field] === undefined) continue;
    const listChanges = parseListChanges(field, record[field]);
    if (listChanges) Object.assign(changes, {[field]: listChanges});
  }

  if (Object.keys(changes).length === 0) {
    throw invalid("Nenhuma alteração informada.");
  }
  return {id, changes};
}

/** Valida o 'id' do cavalo consultado.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {ObjectId} _id do cavalo.
 */
export function validateHorseId(data: unknown): ObjectId {
  return parseObjectId(asRecord(data).id, "Cavalo inválido.");
}

/** Valida a inclusão de um item em uma lista de saúde: 'id', 'lista'
 * (limitacoesFisicas, observacoesSaude ou historicoLesoes) e 'item' (texto,
 * ou { data, descricao, prescricao } para lesões).
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {HorseHealthEntryInput} Dados validados.
 */
export function validateHorseHealthEntry(
  data: unknown
): HorseHealthEntryInput {
  const record = asRecord(data);
  assertAllowedFields(record, ["id", "lista", "item"]);
  const id = parseObjectId(record.id, "Cavalo inválido.");
  const lista = record.lista as keyof HorseHealthLists;
  if (!LISTS.includes(lista)) {
    throw invalid(`Lista inválida. Use ${LISTS.join(", ")}.`);
  }
  if (record.item === undefined || record.item === null) {
    throw invalid("Informe o item a incluir.");
  }
  return {
    id,
    lista,
    item: LIST_RULES[lista].parseItem(record.item),
  } as HorseHealthEntryInput;
}
