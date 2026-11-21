// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Consulta leve da conta (código, nome e situação).
//
// Data: 28/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Edição do nome do responsável e atualização das suas cópias.
//
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Atualização exclusiva do vínculo do responsável com modalidades.
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
import type {
  GuardianAccount,
  GuardianDocument,
  GuardianModality,
  NewGuardian,
  GuardianHomeSource,
} from "../types";

/** Grava o responsável e devolve o código sequencial atribuído.
 * @param {NewGuardian} guardian Dados do responsável.
 * @param {ClientSession} session Sessão da transação.
 */
export async function insertGuardian(
  guardian: NewGuardian,
  session: ClientSession
): Promise<number> {
  const db = await getDatabase();
  const codigo = await nextCode(COLLECTIONS.Responsaveis, session);

  await db
    .collection<GuardianDocument>(COLLECTIONS.Responsaveis)
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
    .collection<GuardianDocument>(COLLECTIONS.Responsaveis)
    .findOne({_id: uid});
}

/** Busca só o necessário para conferir a conta e referenciá-la (código,
 * nome e situação), sem as listas do documento.
 * @param {string} uid UID do usuário.
 */
export async function findGuardianAccount(
  uid: string
): Promise<GuardianAccount | null> {
  const db = await getDatabase();
  return db
    .collection<GuardianDocument>(COLLECTIONS.Responsaveis)
    .findOne<GuardianAccount>(
      {_id: uid},
      {projection: {codigo: 1, nome: 1, situacaoCadastral: 1}}
    );
}

/** Busca os dados mínimos do responsável usados pela home.
 * @param {string} uid UID do usuário.
 */
export async function findGuardianHomeSource(
  uid: string
): Promise<GuardianHomeSource | null> {
  const db = await getDatabase();
  return db
    .collection<GuardianDocument>(COLLECTIONS.Responsaveis)
    .findOne<GuardianHomeSource>(
      {_id: uid},
      {projection: {nome: 1, situacaoCadastral: 1, cavalos: 1}}
    );
}

/** Substitui apenas a lista de modalidades do responsável.
 * Nenhum outro campo é alterado além de 'atualizadoEm'.
 * @param {string} uid UID do usuário.
 * @param {GuardianModality[]} modalidades Novos vínculos.
 * @param {Date} atualizadoEm Data da alteração.
 * @return {Promise<boolean>} Se o responsável foi encontrado.
 */
export async function updateGuardianModalities(
  uid: string,
  modalidades: GuardianModality[],
  atualizadoEm: Date
): Promise<boolean> {
  const db = await getDatabase();
  const result = await db
    .collection<GuardianDocument>(COLLECTIONS.Responsaveis)
    .updateOne({_id: uid}, {$set: {modalidades, atualizadoEm}});
  return result.matchedCount === 1;
}

/** Substitui apenas o nome do responsável ativo.
 * Nenhum outro campo é alterado além de 'atualizadoEm'.
 * @param {string} uid UID do usuário.
 * @param {string} nome Nome completo validado.
 * @param {Date} atualizadoEm Data da alteração.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<GuardianDocument|null>} Perfil atualizado.
 */
export async function updateGuardianName(
  uid: string,
  nome: string,
  atualizadoEm: Date,
  session: ClientSession
): Promise<GuardianDocument | null> {
  const db = await getDatabase();
  return db
    .collection<GuardianDocument>(COLLECTIONS.Responsaveis)
    .findOneAndUpdate(
      {_id: uid, situacaoCadastral: "ATIVO"},
      {$set: {nome, atualizadoEm}},
      {returnDocument: "after", session}
    );
}

/** Atualiza o nome do responsável nas cópias de cavalos e treinadores.
 * Só altera as cópias com nome diferente, então pode ser chamada sempre.
 * @param {string} uid UID do responsável.
 * @param {string} nome Novo nome.
 * @param {ClientSession} session Sessão da transação.
 */
export async function renameGuardianRefs(
  uid: string,
  nome: string,
  session: ClientSession
): Promise<void> {
  const db = await getDatabase();
  const atualizadoEm = new Date();
  const horses = db.collection(COLLECTIONS.Cavalos);

  await Promise.all([
    // cavalos.proprietario e cavalos.atleta.
    ...["proprietario", "atleta"].map((ref) =>
      horses.updateMany(
        {[`${ref}._id`]: uid, [`${ref}.nome`]: {$ne: nome}},
        {$set: {[`${ref}.nome`]: nome, atualizadoEm}},
        {session}
      )
    ),
    db.collection(COLLECTIONS.Treinadores).updateMany(
      {clientes: {$elemMatch: {_id: uid, nome: {$ne: nome}}}},
      {$set: {"clientes.$[cliente].nome": nome, atualizadoEm}},
      {arrayFilters: [{"cliente._id": uid}], session}
    ),
  ]);
}
