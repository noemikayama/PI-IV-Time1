// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Busca da conta pelo e-mail, usada nos vínculos do cavalo.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Reserva de e-mails para evitar cadastros duplicados.
// -----------------------------------------------------------------------------

// A coleção 'emails' garante e-mail único entre perfis.
// Índices: o próprio _id (o e-mail em minúsculo).
import type {ClientSession} from "mongodb";
import {getDatabase} from "../../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../../shared/constants/collections";
import {AppError} from "../../../../shared/errors/AppError";
import {
  isDuplicateKeyError,
} from "../../../../shared/errors/isDuplicateKeyError";
import type {EmailReservation} from "../types";

/** Busca a reserva de um e-mail já normalizado (minúsculas).
 * @param {string} email E-mail, que é o próprio _id.
 * @return {Promise<EmailReservation|null>} Reserva ou null.
 */
export async function findEmail(
  email: string
): Promise<EmailReservation | null> {
  const db = await getDatabase();
  return db
    .collection<EmailReservation>(COLLECTIONS.Emails)
    .findOne({_id: email});
}

/** Reserva um e-mail durante o cadastro dentro da transação.
 * @param {EmailReservation} reservation Dados da reserva.
 * @param {ClientSession} session Sessão da transação.
 */
export async function reserveEmail(
  reservation: EmailReservation,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();

  try {
    await db
      .collection<EmailReservation>(COLLECTIONS.Emails)
      .insertOne(reservation, {session});
  } catch (error) {
    if (isDuplicateKeyError(error)) {
      throw new AppError("already-exists", "E-mail já cadastrado.");
    }
    throw error;
  }
}
