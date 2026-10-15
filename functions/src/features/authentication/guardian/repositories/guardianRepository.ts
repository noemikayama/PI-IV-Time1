// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Padronização do formato da consulta da home.
//
// Data: 14/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Obtenção de dados da home
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Gravação do perfil do responsável e geração do código.
// -----------------------------------------------------------------------------

// Coleção 'responsaveis'.
// O _id (UID do Firebase) já é único; não há índices extras.
import type {ClientSession} from "mongodb";
import {getDatabase} from "../../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../../shared/constants/collections";
import {nextCode} from "../../../../shared/database/sequence";
import type {GuardianDocument, NewGuardian, GuardianHomeSource} from "../types";

/** Grava o responsável e devolve o código sequencial atribuído.
 * @param {NewGuardian} guardian Dados do responsável.
 * @param {ClientSession} session Sessão da transação.
 */
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

/** Busca o cadastro do responsável pelo UID do Firebase.
 * @param {string} uid UID do usuário.
 */
export async function findGuardianById(
  uid: string
): Promise<GuardianDocument | null> {
  const db = await getDatabase();
  return db
    .collection<GuardianDocument>(COLLECTIONS.responsaveis)
    .findOne({_id: uid});
}

/** Busca os dados mínimos do responsável usados pela home.
 * @param {string} uid UID do usuário.
 */
export async function findGuardianHomeSource(
  uid: string
): Promise<GuardianHomeSource | null> {
  const db = await getDatabase();
  return db
    .collection<GuardianDocument>(COLLECTIONS.responsaveis)
    .findOne<GuardianHomeSource>(
      {_id: uid},
      {projection: {nome: 1, situacaoCadastral: 1, cavalos: 1}}
    );
}
