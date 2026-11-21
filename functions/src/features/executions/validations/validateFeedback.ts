// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Validação do feedback do treinador.
// -----------------------------------------------------------------------------

import {asRecord, assertAllowedFields} from "../../authentication/shared";
import {MAX_COMMENT_LENGTH} from "../constants/limits";
import type {FeedbackInput} from "../types";
import {invalid, parseTextList} from "./textFields";
import {INVALID_DATA_MESSAGE, parseRecordId} from "./validateTrainingRecord";

/** Valida o envio do feedback. O comentário é obrigatório; dificuldades
 * identificadas e orientações são listas opcionais (o app quebra o texto
 * digitado em linhas). A data é definida pelo servidor.
 * @param {unknown} data Dados recebidos pelo endpoint.
 * @return {FeedbackInput} Feedback normalizado.
 */
export function validateFeedback(data: unknown): FeedbackInput {
  const record = asRecord(data ?? {}, INVALID_DATA_MESSAGE);
  assertAllowedFields(record, [
    "registroId",
    "comentario",
    "dificuldadesIdentificadas",
    "orientacoes",
  ]);
  const registroId = parseRecordId(record.registroId);
  const comentario =
    typeof record.comentario === "string" ? record.comentario.trim() : "";
  if (comentario.length < 1 || comentario.length > MAX_COMMENT_LENGTH) {
    throw invalid(
      `O comentário deve ter entre 1 e ${MAX_COMMENT_LENGTH} caracteres.`
    );
  }
  return {
    registroId,
    comentario,
    dificuldadesIdentificadas: parseTextList(
      record.dificuldadesIdentificadas,
      "Dificuldades identificadas",
      "Cada dificuldade identificada deve ter até 500 caracteres."
    ),
    orientacoes: parseTextList(
      record.orientacoes,
      "Orientações",
      "Cada orientação deve ter até 500 caracteres."
    ),
  };
}
