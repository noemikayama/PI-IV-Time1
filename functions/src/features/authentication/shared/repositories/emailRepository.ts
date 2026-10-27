// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Reserva de e-mails para evitar cadastros duplicados.
// -----------------------------------------------------------------------------

// A coleção 'emails' garante e-mail único entre perfis.
// Índices: o próprio _id (o e-mail em minúsculo).
import {MongoServerError} from "mongodb";
import type {ClientSession} from "mongodb";
import {getDatabase} from "../../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../../shared/constants/collections";
import {AppError} from "../../../../shared/errors/AppError";
import type {EmailReservation} from "../types";

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
    if (error instanceof MongoServerError && error.code === 11000) {
      throw new AppError("already-exists", "E-mail já cadastrado.");
    }
    throw error;
  }
}
