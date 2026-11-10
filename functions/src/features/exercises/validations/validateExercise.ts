// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 07/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do cadastro de exercícios.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {asRecord} from "../../authentication/shared";
import type {
  ExerciseDetailsInput,
  ExerciseMaterial,
  ExercisePrivacy,
  ExerciseRegistrationInput,
} from "../types";

const PRIVACIES: readonly ExercisePrivacy[] = ["GENERICO", "ESPECIFICO"];
const MAX_ORIENTATIONS = 30;
const MAX_MATERIALS = 30;
const MAX_ITEM_LENGTH = 500;
const MAX_DURATION_MINUTES = 240;
const MAX_MATERIAL_QUANTITY = 999;

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

/** Valida um inteiro dentro do intervalo informado.
 * @param {unknown} value Valor recebido.
 * @param {string} label Nome do campo usado na mensagem.
 * @param {number} min Valor mínimo.
 * @param {number} max Valor máximo.
 * @return {number} Inteiro validado.
 */
function parseInteger(
  value: unknown,
  label: string,
  min: number,
  max: number
): number {
  if (
    typeof value !== "number" ||
    !Number.isInteger(value) ||
    value < min ||
    value > max
  ) {
    throw invalid(`${label} deve ser um número inteiro entre ${min} e ${max}.`);
  }
  return value;
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

/** Valida as orientações (opcionais), sem itens vazios.
 * @param {unknown} value Valor recebido.
 * @return {string[]} Orientações normalizadas.
 */
function parseOrientacoes(value: unknown): string[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > MAX_ORIENTATIONS) {
    throw invalid(
      `Orientações: informe no máximo ${MAX_ORIENTATIONS} itens.`
    );
  }
  return value.map((item) =>
    parseText(item, "Cada orientação", 1, MAX_ITEM_LENGTH)
  );
}

/** Valida os materiais: descrição, quantidade e sem repetição.
 * @param {unknown} value Valor recebido.
 * @return {ExerciseMaterial[]} Materiais normalizados.
 */
function parseMateriais(value: unknown): ExerciseMaterial[] {
  if (value === undefined || value === null) return [];
  if (!Array.isArray(value) || value.length > MAX_MATERIALS) {
    throw invalid(`Materiais: informe no máximo ${MAX_MATERIALS} itens.`);
  }
  const materiais = value.map((item): ExerciseMaterial => {
    const {descricao, quantidade} = asRecord(item, "Material inválido.");
    return {
      descricao: parseText(descricao, "A descrição do material", 1, 100),
      quantidade: parseInteger(
        quantidade,
        "A quantidade do material",
        1,
        MAX_MATERIAL_QUANTITY
      ),
    };
  });

  // O mesmo material deve aparecer uma vez, com a quantidade total.
  const seen = new Set<string>();
  for (const {descricao} of materiais) {
    const key = descricao.toLocaleLowerCase("pt-BR");
    if (seen.has(key)) {
      throw invalid(`Material repetido: ${descricao}.`);
    }
    seen.add(key);
  }
  return materiais;
}

/** Valida a privacidade do exercício.
 * @param {unknown} value Valor recebido.
 * @return {ExercisePrivacy} Privacidade validada.
 */
function parsePrivacidade(value: unknown): ExercisePrivacy {
  if (!PRIVACIES.includes(value as ExercisePrivacy)) {
    throw invalid("Tipo de exercício inválido. Use GENERICO ou ESPECIFICO.");
  }
  return value as ExercisePrivacy;
}

/** Valida o cavalo conforme a privacidade: obrigatório no específico e
 * ausente no genérico. O vínculo com o treinador é conferido no service.
 * @param {unknown} value Valor recebido.
 * @param {ExercisePrivacy} privacidade Privacidade já validada.
 * @return {ObjectId|null} _id do cavalo ou null.
 */
function parseCavaloId(
  value: unknown,
  privacidade: ExercisePrivacy
): ObjectId | null {
  const informed = value !== undefined && value !== null;
  if (privacidade === "GENERICO") {
    if (informed) {
      throw invalid("Exercício genérico não pode ter cavalo.");
    }
    return null;
  }
  if (!informed) {
    throw invalid("Selecione o cavalo do exercício específico.");
  }
  return parseObjectId(value, "Cavalo inválido.");
}

// Um parser por campo editável; compartilhado entre cadastro e edição.
const DETAIL_PARSERS: {
  [K in keyof ExerciseDetailsInput]: (
    value: unknown
  ) => ExerciseDetailsInput[K];
} = {
  nome: (value) => parseText(value, "O nome", 3, 80),
  descricao: (value) => parseText(value, "A descrição", 1, 1000),
  orientacoes: parseOrientacoes,
  duracaoPadraoMinutos: (value) =>
    parseInteger(value, "A duração padrão", 1, MAX_DURATION_MINUTES),
  materiais: parseMateriais,
};

const DETAIL_FIELDS = Object.keys(DETAIL_PARSERS) as
  (keyof ExerciseDetailsInput)[];

/** Valida e normaliza os dados do cadastro de exercício.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {ExerciseRegistrationInput} Dados validados e normalizados.
 */
export function validateExerciseRegistration(
  data: unknown
): ExerciseRegistrationInput {
  const record = asRecord(data);
  const details = Object.fromEntries(
    DETAIL_FIELDS.map((field) => [field, DETAIL_PARSERS[field](record[field])])
  ) as ExerciseDetailsInput;
  const privacidade = parsePrivacidade(record.privacidade);

  return {
    ...details,
    privacidade,
    cavaloId: parseCavaloId(record.cavaloId, privacidade),
  };
}

/** Valida o 'id' do exercício.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {ObjectId} _id do exercício.
 */
export function validateExerciseId(data: unknown): ObjectId {
  return parseObjectId(asRecord(data).id, "Exercício inválido.");
}
