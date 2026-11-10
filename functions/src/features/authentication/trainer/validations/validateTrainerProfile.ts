// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação da situação profissional (sem INATIVO).
//
// Data: 29/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação dos dados da edição do perfil do treinador.
// -----------------------------------------------------------------------------

import {AppError} from "../../../../shared/errors/AppError";
import {asRecord, assertAllowedFields, parseFullName} from "../../shared";
import {MAX_CERTIFICATIONS} from "../constants/attachments";
import {MAX_SERVICE_REGIONS} from "../constants/serviceRegions";
import type {
  EditableProfessionalStatus,
  ServiceRegion,
  UpdateTrainerProfileInput,
} from "../types";
import {parseCaminho} from "./validateTrainerAttachment";
import {parseRegion} from "./validateTrainerRegistration";

// _id, codigo, email, senha, modalidades, cavalos, clientes e as datas são
// recusados.
const EDITABLE_FIELDS = [
  "nome",
  "sobrenome",
  "situacaoProfissional",
  "regioesAtendimento",
  "experiencias",
  "certificacoes",
];

const PROFESSIONAL_STATUSES: readonly EditableProfessionalStatus[] = [
  "DISPONIVEL",
  "AFASTADO",
  "INDISPONIVEL",
];

/** Cria um erro de argumento inválido com a mensagem informada.
 * @param {string} message Mensagem do erro.
 * @return {AppError} Erro de argumento inválido.
 */
function invalid(message: string): AppError {
  return new AppError("invalid-argument", message);
}

/** Valida a situação profissional escolhida pelo treinador. INATIVO é
 * exclusão lógica da conta e não é aceito aqui.
 * @param {unknown} value Valor recebido.
 * @return {EditableProfessionalStatus} Situação validada.
 */
function parseProfessionalStatus(value: unknown): EditableProfessionalStatus {
  if (!PROFESSIONAL_STATUSES.includes(value as EditableProfessionalStatus)) {
    throw invalid(
      "Situação profissional inválida. Use DISPONIVEL, AFASTADO ou " +
        "INDISPONIVEL."
    );
  }
  return value as EditableProfessionalStatus;
}

/** Valida uma lista de regiões; ausente vale como lista vazia.
 * @param {unknown} value Valor recebido.
 * @return {ServiceRegion[]} Regiões normalizadas.
 */
function parseRegionList(value: unknown): ServiceRegion[] {
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.length > MAX_SERVICE_REGIONS) {
    throw invalid("Regiões de atendimento inválidas.");
  }
  return value.map(parseRegion);
}

/** Valida as regiões a adicionar e a remover. Duplicidade e existência são
 * conferidas no service, contra as regiões gravadas.
 * @param {unknown} value Valor recebido.
 * @return {Object|undefined} Operações, ou undefined se não houver nenhuma.
 */
function parseRegionChanges(
  value: unknown
): UpdateTrainerProfileInput["regioesAtendimento"] {
  const record = asRecord(value, "Regiões de atendimento inválidas.");
  assertAllowedFields(record, ["adicionar", "remover"]);
  const adicionar = parseRegionList(record.adicionar);
  const remover = parseRegionList(record.remover);
  if (adicionar.length === 0 && remover.length === 0) return undefined;
  return {adicionar, remover};
}

/** Valida os caminhos das certificações a remover, sem repetição.
 * @param {unknown} value Valor recebido.
 * @return {Object|undefined} Caminhos, ou undefined se a lista for vazia.
 */
function parseCertificationChanges(
  value: unknown
): UpdateTrainerProfileInput["certificacoes"] {
  const record = asRecord(value, "Certificações inválidas.");
  assertAllowedFields(record, ["remover"]);
  const {remover} = record;
  if (!Array.isArray(remover) || remover.length > MAX_CERTIFICATIONS) {
    throw invalid("Certificações inválidas.");
  }
  if (remover.length === 0) return undefined;
  return {remover: [...new Set(remover.map(parseCaminho))]};
}

/** Valida a edição do perfil. Apenas os campos enviados são alterados;
 * nome e sobrenome vêm juntos e são gravados em 'nome'. A posse dos caminhos
 * dos anexos é conferida no service.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {UpdateTrainerProfileInput} Alterações validadas.
 */
export function validateTrainerProfileUpdate(
  data: unknown
): UpdateTrainerProfileInput {
  const record = asRecord(data);
  assertAllowedFields(record, EDITABLE_FIELDS);
  const input: UpdateTrainerProfileInput = {};

  if (record.nome !== undefined || record.sobrenome !== undefined) {
    input.nome = parseFullName(record.nome, record.sobrenome);
  }
  if (record.situacaoProfissional !== undefined) {
    input.situacaoProfissional = parseProfessionalStatus(
      record.situacaoProfissional
    );
  }
  if (record.regioesAtendimento !== undefined) {
    input.regioesAtendimento = parseRegionChanges(record.regioesAtendimento);
  }
  if (record.experiencias !== undefined) {
    const experiencias = asRecord(record.experiencias, "Experiência inválida.");
    assertAllowedFields(experiencias, ["remover"]);
    input.experiencias = {remover: parseCaminho(experiencias.remover)};
  }
  if (record.certificacoes !== undefined) {
    input.certificacoes = parseCertificationChanges(record.certificacoes);
  }

  if (Object.values(input).every((value) => value === undefined)) {
    throw invalid("Nenhuma alteração informada.");
  }
  return input;
}
