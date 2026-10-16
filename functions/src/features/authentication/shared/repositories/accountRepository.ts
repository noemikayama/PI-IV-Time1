// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Busca da conta pelo UID do Firebase para o login.
// -----------------------------------------------------------------------------

import {getDatabase} from "../../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../../shared/constants/collections";
import {ROLES} from "../../../../shared/constants/roles";
import type {GuardianDocument} from "../../guardian/types";
import type {TrainerDocument} from "../../trainer/types";
import type {AccountLookup} from "../types";

type GuardianAccount = Pick<GuardianDocument, "nome" | "situacaoCadastral">;
type TrainerAccount = Pick<
    TrainerDocument,
    "nome" | "situacaoProfissional"
>;

/** Busca a conta do usuário pelo UID do Firebase Authentication.
 * @param {string} uid UID do usuário.
 */
export async function findAccountByUid(
  uid: string
): Promise<AccountLookup | null> {
  const db = await getDatabase();

  const [guardian, trainer] = await Promise.all([
    db
      .collection<GuardianDocument>(COLLECTIONS.Responsaveis)
      .findOne<GuardianAccount>(
        {_id: uid},
        {projection: {nome: 1, situacaoCadastral: 1}}
      ),
    db
      .collection<TrainerDocument>(COLLECTIONS.Treinadores)
      .findOne<TrainerAccount>(
        {_id: uid},
        {projection: {nome: 1, situacaoProfissional: 1}}
      ),
  ]);

  if (guardian) {
    return {
      role: ROLES.guardian,
      nome: guardian.nome,
      active: guardian.situacaoCadastral === "ATIVO",
    };
  }
  if (trainer) {
    return {
      role: ROLES.trainer,
      nome: trainer.nome,
      active: trainer.situacaoProfissional !== "INATIVO",
    };
  }
  return null;
}
