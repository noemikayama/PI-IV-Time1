// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 04/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação do desvínculo de atleta ou treinador.
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Validação da edição dos vínculos do cavalo.
// -----------------------------------------------------------------------------

import {AppError} from "../../../shared/errors/AppError";
import {
  asRecord,
  assertAllowedFields,
  parseEmail,
} from "../../authentication/shared";
import type {HorseLinkKind, HorseLinksInput, HorseUnlinkInput} from "../types";
import {validateHorseId} from "./validateHorse";

const LINK_KINDS: readonly HorseLinkKind[] = ["ATLETA", "TREINADOR"];

/** Valida um e-mail opcional: ausente, nulo ou vazio mantém o vínculo.
 * @param {unknown} value Valor recebido.
 * @param {string} label Vínculo usado na mensagem.
 * @return {string|undefined} E-mail normalizado.
 */
function parseOptionalEmail(
  value: unknown,
  label: string
): string | undefined {
  if (value === undefined || value === null) return undefined;
  if (typeof value === "string" && value.trim() === "") return undefined;
  try {
    return parseEmail(value);
  } catch {
    throw new AppError("invalid-argument", `E-mail do ${label} inválido.`);
  }
}

/** Valida o pedido de vínculo: 'id' e o e-mail do atleta e/ou do treinador.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {HorseLinksInput} Dados validados.
 */
export function validateHorseLinks(data: unknown): HorseLinksInput {
  const record = asRecord(data, "Dados de vínculo inválidos.");
  assertAllowedFields(record, ["id", "emailAtleta", "emailTreinador"]);

  const emailAtleta = parseOptionalEmail(record.emailAtleta, "atleta");
  const emailTreinador = parseOptionalEmail(
    record.emailTreinador,
    "treinador"
  );
  if (!emailAtleta && !emailTreinador) {
    throw new AppError(
      "invalid-argument",
      "Informe o e-mail do treinador e/ou do atleta."
    );
  }
  return {
    id: validateHorseId(record),
    ...(emailAtleta && {emailAtleta}),
    ...(emailTreinador && {emailTreinador}),
  };
}

/** Valida o desvínculo: 'id' e o 'vinculo' desfeito (ATLETA ou TREINADOR).
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {HorseUnlinkInput} Dados validados.
 */
export function validateHorseUnlink(data: unknown): HorseUnlinkInput {
  const record = asRecord(data, "Dados de vínculo inválidos.");
  assertAllowedFields(record, ["id", "vinculo"]);

  const vinculo = record.vinculo as HorseLinkKind;
  if (!LINK_KINDS.includes(vinculo)) {
    throw new AppError(
      "invalid-argument",
      "Vínculo inválido. Use ATLETA ou TREINADOR."
    );
  }
  return {id: validateHorseId(record), vinculo};
}
