// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Busca da conta pelo UID do Firebase para o login.
// -----------------------------------------------------------------------------

import {getDatabase} from "../../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../../shared/constants/collections";
import {ROLES} from "../../../../shared/constants/roles";
import type {GuardianDocument} from "../../guardian/types";
import type {ProfessionalDocument} from "../../professional/types";
import type {AccountLookup} from "../types";

type GuardianAccount = Pick<GuardianDocument, "nome" | "situacaoCadastral">;
type ProfessionalAccount = Pick<
    ProfessionalDocument,
    "nome" | "situacaoProfissional"
>;

/** Busca a conta do usuário pelo UID do Firebase Authentication.
 * @param {string} uid UID do usuário.
 */
export async function findAccountByUid(
  uid: string
): Promise<AccountLookup | null> {
  const db = await getDatabase();

  const [guardian, professional] = await Promise.all([
    db
      .collection<GuardianDocument>(COLLECTIONS.responsaveis)
      .findOne<GuardianAccount>(
        {_id: uid},
        {projection: {nome: 1, situacaoCadastral: 1}}
      ),
    db
      .collection<ProfessionalDocument>(COLLECTIONS.treinadores)
      .findOne<ProfessionalAccount>(
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
  if (professional) {
    return {
      role: ROLES.professional,
      nome: professional.nome,
      active: professional.situacaoProfissional !== "INATIVO",
    };
  }
  return null;
}
