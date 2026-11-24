// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 29/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação de uma região exportada para a edição do perfil.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação dos dados enviados no cadastro de treinadores.
// -----------------------------------------------------------------------------

import {AppError} from "../../../../shared/errors/AppError";
import {asRecord, parseCredentials} from "../../shared";
import {MAX_SERVICE_REGIONS} from "../constants/serviceRegions";
import type {TrainerRegistrationInput, ServiceRegion} from "../types";

/** Cria um erro de argumento inválido com a mensagem informada.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro de argumento inválido.
 */
function invalid(message: string): AppError {
  return new AppError("invalid-argument", message);
}

/** Valida e normaliza as modalidades informadas no cadastro.
 * @param {unknown} value Valor recebido.
 * @return {string[]} Modalidades normalizadas.
 */
function parseModalidades(value: unknown): string[] {
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.length > 20) {
    throw invalid("Modalidades inválidas.");
  }
  return value.map((item) => {
    if (typeof item !== "string" || item.trim() === "" || item.length > 60) {
      throw invalid("Modalidades inválidas.");
    }
    return item.trim();
  });
}

/** Valida e normaliza uma região de atendimento.
 * @param {unknown} item Valor recebido.
 * @return {ServiceRegion} Região normalizada.
 */
export function parseRegion(item: unknown): ServiceRegion {
  const {estado, cidade, complemento} = asRecord(
    item,
    "Região de atendimento inválida."
  );

  if (typeof estado !== "string" || !/^[A-Z]{2}$/.test(estado)) {
    throw invalid("O estado deve ser a sigla com 2 letras maiúsculas.");
  }
  if (
    typeof cidade !== "string" ||
    cidade.trim() === "" ||
    cidade.length > 100
  ) {
    throw invalid("Cidade inválida.");
  }
  if (complemento === undefined) return {estado, cidade: cidade.trim()};
  if (
    typeof complemento !== "string" ||
    complemento.trim() === "" ||
    complemento.length > 150
  ) {
    throw invalid("Complemento inválido.");
  }
  return {estado, cidade: cidade.trim(), complemento: complemento.trim()};
}

/** Valida e normaliza as regiões de atendimento.
 * @param {unknown} value Valor recebido.
 * @return {ServiceRegion[]} Regiões normalizadas.
 */
function parseRegioes(value: unknown): ServiceRegion[] {
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.length > MAX_SERVICE_REGIONS) {
    throw invalid("Regiões de atendimento inválidas.");
  }
  return value.map(parseRegion);
}

/** Valida e normaliza os dados do cadastro de treinador.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {TrainerRegistrationInput} Dados validados e normalizados.
 */
export function validateTrainerRegistration(
  data: unknown
): TrainerRegistrationInput {
  const record = asRecord(data);
  return {
    ...parseCredentials(record),
    modalidades: parseModalidades(record.modalidades),
    regioesAtendimento: parseRegioes(record.regioesAtendimento),
  };
}
