// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cadastro do responsável no Firebase Auth e no MongoDB.
// -----------------------------------------------------------------------------

import {runInTransaction} from "../../../../shared/config/mongodb";
import {ROLES} from "../../../../shared/constants/roles";
import {createAuthAccount, deleteAuthAccount, reserveEmail} from "../../shared";
import {insertGuardian} from "../repositories/guardianRepository";
import type {
  GuardianRegistrationInput,
  GuardianRegistrationResult,
} from "../types";

/** Cria a conta e o perfil de um responsável.
 * @param {GuardianRegistrationInput} input Dados validados do cadastro.
 */
export async function registerGuardianService(
  input: GuardianRegistrationInput
): Promise<GuardianRegistrationResult> {
  // O UID do Firebase é o _id do responsável.
  const uid = await createAuthAccount(input, ROLES.guardian);

  try {
    const now = new Date();

    // Perfil (com código sequencial) e reserva do e-mail na mesma transação.
    const codigo = await runInTransaction(async (session) => {
      const generatedCode = await insertGuardian(
        {
          _id: uid,
          nome: input.nome,
          email: input.email,
          situacaoCadastral: "ATIVO",
          cavalos: [],
          modalidades: [],
          criadoEm: now,
          atualizadoEm: now,
        },
        session
      );

      await reserveEmail(
        {
          _id: input.email,
          codigo: generatedCode,
          tipoConta: "RESPONSAVEL",
          usuarioId: uid,
          criadoEm: now,
        },
        session
      );

      return generatedCode;
    });

    return {id: uid, codigo, email: input.email};
  } catch (error) {
    await deleteAuthAccount(uid);
    throw error;
  }
}
