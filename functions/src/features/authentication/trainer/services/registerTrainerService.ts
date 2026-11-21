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
// Alteração: Experiência inicia como null (PDF único, enviado depois).
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cadastro do treinador no Firebase Auth e no MongoDB.
// -----------------------------------------------------------------------------

import {runInTransaction} from "../../../../shared/config/mongodb";
import {ROLES} from "../../../../shared/constants/roles";
import {createAuthAccount, deleteAuthAccount, reserveEmail} from "../../shared";
import {insertTrainer} from "../repositories/trainerRepository";
import type {
  TrainerRegistrationInput,
  TrainerRegistrationResult,
} from "../types";

/** Cria a conta e o perfil de um treinador.
 * @param {TrainerRegistrationInput} input Dados validados do cadastro.
 */
export async function registerTrainerService(
  input: TrainerRegistrationInput
): Promise<TrainerRegistrationResult> {
  // O UID do Firebase é o _id do treinador.
  const uid = await createAuthAccount(input, ROLES.trainer);

  try {
    const now = new Date();

    const codigo = await runInTransaction(async (session) => {
      const generatedCode = await insertTrainer(
        {
          _id: uid,
          nome: input.nome,
          email: input.email,
          situacaoProfissional: "DISPONIVEL",
          modalidades: input.modalidades,
          experiencias: null,
          certificacoes: [],
          regioesAtendimento: input.regioesAtendimento,
          cavalos: [],
          clientes: [],
          criadoEm: now,
          atualizadoEm: now,
        },
        session
      );

      await reserveEmail(
        {
          _id: input.email,
          codigo: generatedCode,
          tipoConta: "TREINADOR",
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
