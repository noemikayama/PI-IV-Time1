// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Reserva de e-mails para evitar cadastros duplicados.
// ----------------------------------------------------------------------------- 

// Coleção 'emails' — garante e-mail único entre responsáveis e treinadores.
// Índices: o próprio _id (o e-mail em minúsculo).
import {MongoServerError} from "mongodb";
import type {ClientSession} from "mongodb";
import {getDatabase} from "../../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../../shared/constants/collections";
import {AppError} from "../../../../shared/errors/AppError";
import type {EmailReservation} from "../types";

export async function reserveEmail(
    reservation: EmailReservation,
    session: ClientSession
): Promise<void> {
    const db = await getDatabase();

    try {
        await db
            .collection<EmailReservation>(COLLECTIONS.emails)
            .insertOne(reservation, {session});
    } catch (error) {
        if (error instanceof MongoServerError && error.code === 11000) {
            throw new AppError("already-exists", "E-mail já cadastrado.");
        }
        throw error;
    }
}
