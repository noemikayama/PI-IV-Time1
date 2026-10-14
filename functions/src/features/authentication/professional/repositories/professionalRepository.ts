// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Gravação do perfil do treinador e geração do código.
// ----------------------------------------------------------------------------- 

// Coleção 'treinadores'.
// Índices: o _id (UID do Firebase) já é único; nenhum índice extra por enquanto.
import type {ClientSession} from "mongodb";
import {getDatabase} from "../../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../../shared/constants/collections";
import {nextCode} from "../../../../shared/database/sequence";
import type {NewProfessional, ProfessionalDocument} from "../types";

// Gera o 'codigo' sequencial, grava o treinador e devolve o código.
export async function insertProfessional(
    professional: NewProfessional,
    session: ClientSession): Promise<number> {
    const db = await getDatabase();
    const codigo = await nextCode(COLLECTIONS.treinadores, session);

    await db
        .collection<ProfessionalDocument>(COLLECTIONS.treinadores)
        .insertOne({...professional, codigo}, {session});

    return codigo;
}

// Busca o treinador pelo UID do Firebase (_id).
export async function findProfessionalById(
    uid: string
): Promise<ProfessionalDocument | null> {
    const db = await getDatabase();
    return db
        .collection<ProfessionalDocument>(COLLECTIONS.treinadores)
        .findOne({_id: uid});
}
