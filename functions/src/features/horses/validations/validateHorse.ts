// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do cadastro, da edição e da consulta de cavalos.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {getTodayYmd, isValidYmd} from "../../../shared/utils/dates";
import {asRecord} from "../../authentication/shared";
import type {
  HorseDetailsInput,
  HorseRegistrationInput,
  HorseResponsibility,
  HorseSex,
  HorseUpdateInput,
  InjuryRecord,
} from "../types";

const MICROCHIP_PATTERN = /^\d{15}$/;
const SEXES: readonly HorseSex[] = ["MACHO", "FEMEA"];
const RESPONSIBILITIES: readonly HorseResponsibility[] = [
  "PROPRIETARIO",
  "ATLETA",
];
const MAX_AGE_YEARS = 50;
const MAX_LIST_ITEMS = 30;
const MAX_INJURIES = 50;
const MAX_ITEM_LENGTH = 500;

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

/** Valida uma lista opcional de textos, sem itens vazios.
 * @param {unknown} value Valor recebido.
 * @param {string} label Nome do campo usado na mensagem.
 * @return {string[]} Itens normalizados.
 */
function parseTextList(value: unknown, label: string): string[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > MAX_LIST_ITEMS) {
    throw invalid(`${label}: informe no máximo ${MAX_LIST_ITEMS} itens.`);
  }
  return value.map((item) =>
    parseText(item, `Cada item de ${label.toLowerCase()}`, 1, MAX_ITEM_LENGTH)
  );
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

/** Valida a modalidade opcional (ausente ou null = sem modalidade).
 * @param {unknown} value Valor recebido.
 * @return {ObjectId|null} _id da modalidade.
 */
function parseModalidadeId(value: unknown): ObjectId | null {
  if (value === undefined || value === null) return null;
  return parseObjectId(value, "Modalidade inválida.");
}

/** Valida o histórico de lesões e o ordena da mais recente à mais antiga.
 * @param {unknown} value Valor recebido.
 * @return {InjuryRecord[]} Lesões normalizadas.
 */
function parseInjuries(value: unknown): InjuryRecord[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > MAX_INJURIES) {
    throw invalid(
      `Histórico de lesões: informe no máximo ${MAX_INJURIES} lesões.`
    );
  }
  const injuries = value.map((item): InjuryRecord => {
    const {data, descricao, prescricao} = asRecord(item);
    const injury: InjuryRecord = {
      data: parsePastDate(data, "Data da lesão"),
      descricao: parseText(
        descricao,
        "A descrição da lesão",
        1,
        MAX_ITEM_LENGTH
      ),
    };
    // A prescrição médica é opcional; texto vazio equivale a não informar.
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
  });
  return injuries.sort((a, b) => b.data.localeCompare(a.data));
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
function parseMicrochip(value: unknown): string {
  const codigo = typeof value === "string" ? value.trim() : "";
  if (!MICROCHIP_PATTERN.test(codigo)) {
    throw invalid("O microchip deve ter exatamente 15 dígitos numéricos.");
  }
  return codigo;
}

// Um parser por campo editável; compartilhado entre cadastro e edição.
const DETAIL_PARSERS: {
  [K in keyof HorseDetailsInput]: (value: unknown) => HorseDetailsInput[K];
} = {
  nome: (value) => parseText(value, "O nome", 2, 80),
  dataNascimento: parseBirthDate,
  raca: (value) => parseText(value, "A raça", 1, 60),
  pelagem: (value) => parseText(value, "A pelagem", 1, 60),
  sexo: parseSexo,
  modalidadeId: parseModalidadeId,
  limitacoesFisicas: (value) => parseTextList(value, "Limitações físicas"),
  observacoesSaude: (value) => parseTextList(value, "Observações de saúde"),
  historicoLesoes: parseInjuries,
};

const DETAIL_FIELDS = Object.keys(DETAIL_PARSERS) as
  (keyof HorseDetailsInput)[];

/** Garante que nenhuma lesão seja anterior ao nascimento.
 * @param {string} dataNascimento Data de nascimento.
 * @param {InjuryRecord[]} lesoes Histórico de lesões.
 */
export function assertInjuriesAfterBirth(
  dataNascimento: string,
  lesoes: InjuryRecord[]
): void {
  if (lesoes.some((lesao) => lesao.data < dataNascimento)) {
    throw invalid("A data da lesão não pode ser anterior ao nascimento.");
  }
}

/** Valida e normaliza os dados do cadastro de cavalo.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {HorseRegistrationInput} Dados validados e normalizados.
 */
export function validateHorseRegistration(
  data: unknown
): HorseRegistrationInput {
  const record = asRecord(data);
  const details = Object.fromEntries(
    DETAIL_FIELDS.map((field) => [field, DETAIL_PARSERS[field](record[field])])
  ) as HorseDetailsInput;

  return {
    ...details,
    codigo: parseMicrochip(record.codigo),
    responsabilidades: parseResponsabilidades(record.responsabilidades),
  };
}

/** Valida a edição: 'id' e apenas os campos enviados.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {HorseUpdateInput} Alterações validadas.
 */
export function validateHorseUpdate(data: unknown): HorseUpdateInput {
  const record = asRecord(data);
  const present = DETAIL_FIELDS.filter((field) => record[field] !== undefined);
  if (present.length === 0) {
    throw invalid("Nenhuma alteração informada.");
  }
  return {
    id: parseObjectId(record.id, "Cavalo inválido."),
    changes: Object.fromEntries(
      present.map((field) => [field, DETAIL_PARSERS[field](record[field])])
    ) as Partial<HorseDetailsInput>,
  };
}

/** Valida o 'id' do cavalo consultado.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {ObjectId} _id do cavalo.
 */
export function validateHorseId(data: unknown): ObjectId {
  return parseObjectId(asRecord(data).id, "Cavalo inválido.");
}
