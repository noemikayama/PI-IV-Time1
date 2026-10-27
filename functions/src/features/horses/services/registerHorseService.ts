// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cadastro do cavalo pelo responsável proprietário.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {
  findGuardianById,
} from "../../authentication/guardian/repositories/guardianRepository";
import {
  addHorseToGuardian,
  ensureHorseIndexes,
  insertHorse,
} from "../repositories/horseRepository";
import type {
  HorseDocument,
  HorseRegistrationInput,
  HorseRegistrationResult,
} from "../types";
import {assertInjuriesAfterBirth} from "../validations/validateHorse";
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

  const guardian = await findGuardianById(uid);
  if (!guardian || guardian.situacaoCadastral !== "ATIVO") {
    throw new AppError("permission-denied", "Conta inativa ou inexistente.");
  }

  const [modalidade] = await Promise.all([
    input.modalidadeId ? resolveModality(input.modalidadeId) : undefined,
    ensureHorseIndexes(),
  ]);

  const now = new Date();
  const owner = {_id: uid, codigo: guardian.codigo, nome: guardian.nome};
  const horse: HorseDocument = {
    _id: new ObjectId(),
    codigo: input.codigo,
    nome: input.nome,
    dataNascimento: input.dataNascimento,
    raca: input.raca,
    pelagem: input.pelagem,
    sexo: input.sexo,
    imagens: [],
    ...(modalidade && {modalidade}),
    limitacoesFisicas: input.limitacoesFisicas,
    observacoesSaude: input.observacoesSaude,
    historicoLesoes: input.historicoLesoes,
    situacaoCadastral: "ATIVO",
    proprietario: owner,
    ...(input.responsabilidades.includes("ATLETA") && {atleta: owner}),
    treinadores: [],
    avaliacoes: [],
    criadoEm: now,
    atualizadoEm: now,
  };

  // Cavalo e cópia resumida em responsaveis.cavalos na mesma transação.
  await runInTransaction(async (session) => {
    await insertHorse(horse, session);
    await addHorseToGuardian(
      uid,
      {
        _id: horse._id,
        codigo: horse.codigo,
        nome: horse.nome,
        responsabilidades: input.responsabilidades,
      },
      session
    );
  });

  return {id: horse._id.toHexString(), codigo: horse.codigo, nome: horse.nome};
}
