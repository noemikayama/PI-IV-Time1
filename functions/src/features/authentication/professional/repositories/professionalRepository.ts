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
// Alteração: Obtenção de dados da home.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Gravação do perfil do treinador e geração do código.
// -----------------------------------------------------------------------------

// Coleção 'treinadores'.
// O _id (UID do Firebase) já é único; não há índices extras.
import type {ClientSession} from "mongodb";
import {getDatabase} from "../../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../../shared/constants/collections";
import {nextCode} from "../../../../shared/database/sequence";
import type {
  NewProfessional,
  ProfessionalDocument,
  ProfessionalHomeSource,
} from "../types";

/** Grava o treinador e devolve o código sequencial atribuído.
 * @param {NewProfessional} professional Dados do treinador.
 * @param {ClientSession} session Sessão da transação.
 */
export async function insertProfessional(
  professional: NewProfessional,
  session: ClientSession
): Promise<number> {
  const db = await getDatabase();
  const codigo = await nextCode(COLLECTIONS.treinadores, session);

  await db
    .collection<ProfessionalDocument>(COLLECTIONS.treinadores)
    .insertOne({...professional, codigo}, {session});

  return codigo;
}

/** Busca o cadastro do treinador pelo UID do Firebase.
 * @param {string} uid UID do usuário.
 */
export async function findProfessionalById(
  uid: string
): Promise<ProfessionalDocument | null> {
  const db = await getDatabase();
  return db
    .collection<ProfessionalDocument>(COLLECTIONS.treinadores)
    .findOne({_id: uid});
}

/** Busca os dados mínimos do treinador usados pela home.
 * @param {string} uid UID do usuário.
 */
export async function findProfessionalHomeSource(
  uid: string
): Promise<ProfessionalHomeSource | null> {
  const db = await getDatabase();
  return db
    .collection<ProfessionalDocument>(COLLECTIONS.treinadores)
    .findOne<ProfessionalHomeSource>(
      {_id: uid},
      {
        projection: {
          nome: 1,
          situacaoProfissional: 1,
          cavalos: 1,
          clientes: 1,
        },
      }
    );
}
