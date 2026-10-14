// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Gravação do perfil do responsável e geração do código.
// ----------------------------------------------------------------------------- 

// Coleção 'responsaveis'.
// Índices: o _id (UID do Firebase) já é único; nenhum índice extra por enquanto.
import type {ClientSession} from "mongodb";
import {getDatabase} from "../../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../../shared/constants/collections";
import {nextCode} from "../../../../shared/database/sequence";
import type {GuardianDocument, NewGuardian} from "../types";

// Gera o 'codigo' sequencial, grava o responsável e devolve o código.
export async function insertGuardian(
    guardian: NewGuardian,
    session: ClientSession
): Promise<number> {
    const db = await getDatabase();
    const codigo = await nextCode(COLLECTIONS.responsaveis, session);

    await db
        .collection<GuardianDocument>(COLLECTIONS.responsaveis)
        .insertOne({...guardian, codigo}, {session});

    return codigo;
}

export async function findGuardianById(uid: string): Promise<GuardianDocument | null> {
    const db = await getDatabase();
    return db.collection<GuardianDocument>(COLLECTIONS.responsaveis).findOne({_id: uid});
}
