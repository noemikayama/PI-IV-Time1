// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Modalidade obrigatória.
// Alteração: Data do vínculo do atleta, usada na ordenação da lista.
// Alteração: Regras das lesões vindas de horseHealth.ts; a ordenação das
// lesões passa a ser feita aqui, não na validação.
// Alteração: Cópia em responsaveis.cavalos via horseSummaryRepository.ts.
// Alteração: Conta conferida pela regra única (assertActiveAccount).
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cadastro do cavalo pelo responsável proprietário.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {ensureHorseIndexes, insertHorse} from "../repositories/horseRepository";
import {addHorseToGuardian} from "../repositories/horseSummaryRepository";
import type {
  HorseDocument,
  HorseRegistrationInput,
  HorseRegistrationResult,
} from "../types";
import {assertActiveAccount} from "./horseAccess";
import {assertInjuriesAfterBirth, sortInjuries} from "./horseHealth";
import {resolveModality} from "./resolveModality";

/** Cadastra o cavalo e o acrescenta à lista do responsável.
 * @param {string} uid UID do responsável autenticado.
 * @param {HorseRegistrationInput} input Dados validados do cadastro.
 */
export async function registerHorseService(
  uid: string,
  input: HorseRegistrationInput
): Promise<HorseRegistrationResult> {
  if (!input.responsabilidades.includes("PROPRIETARIO")) {
    throw new AppError(
      "permission-denied",
      "Apenas o proprietário pode cadastrar o cavalo."
    );
  }
  assertInjuriesAfterBirth(input.dataNascimento, input.historicoLesoes);

  // O proprietário, como referência resumida, vem da conferência da conta.
  const owner = await assertActiveAccount(uid, ROLES.guardian);

  const [modalidade] = await Promise.all([
    resolveModality(input.modalidadeId),
    ensureHorseIndexes(),
  ]);

  const now = new Date();
  const horse: HorseDocument = {
    _id: new ObjectId(),
    codigo: input.codigo,
    nome: input.nome,
    dataNascimento: input.dataNascimento,
    raca: input.raca,
    pelagem: input.pelagem,
    sexo: input.sexo,
    imagens: [],
    modalidade,
    limitacoesFisicas: input.limitacoesFisicas,
    observacoesSaude: input.observacoesSaude,
    historicoLesoes: sortInjuries(input.historicoLesoes),
    situacaoCadastral: "ATIVO",
    proprietario: owner,
    ...(input.responsabilidades.includes("ATLETA") && {
      atleta: {...owner, vinculadoEm: now},
    }),
    treinadores: [],
    avaliacoes: [],
    criadoEm: now,
    atualizadoEm: now,
  };

  // Cavalo e cópia resumida em responsaveis.cavalos na mesma transação.
  await runInTransaction(async (session) => {
    await insertHorse(horse, session);
    const added = await addHorseToGuardian(
      uid,
      {_id: horse._id, codigo: horse.codigo, nome: horse.nome},
      input.responsabilidades,
      session
    );
    // Lançar aqui aborta a transação e desfaz a inserção do cavalo.
    if (!added) {
      throw new AppError("permission-denied", "Conta inativa ou inexistente.");
    }
  });

  return {id: horse._id.toHexString(), codigo: horse.codigo, nome: horse.nome};
}
