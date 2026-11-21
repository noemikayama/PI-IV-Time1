// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conferência do vínculo com o cavalo movida para linkedHorse.ts.
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cadastro de exercícios genéricos e específicos pelo treinador.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {findTrainerById} from "../../authentication/trainer";
import {
  ensureExerciseIndexes,
  insertExercise,
} from "../repositories/exerciseRepository";
import {resolveLinkedHorse} from "./linkedHorse";
import type {
  ExerciseRegistrationInput,
  ExerciseRegistrationResult,
  NewExercise,
} from "../types";

/** Cadastra o exercício do treinador. O específico fica ligado a um cavalo
 * vinculado a ele; o genérico, ao acervo do treinador.
 * @param {string} uid UID do treinador autenticado.
 * @param {ExerciseRegistrationInput} input Dados validados do cadastro.
 * @return {Promise<ExerciseRegistrationResult>} Exercício criado.
 */
export async function registerExerciseService(
  uid: string,
  input: ExerciseRegistrationInput
): Promise<ExerciseRegistrationResult> {
  const trainer = await findTrainerById(uid);
  if (!trainer) {
    throw new AppError("permission-denied", "Conta inativa ou inexistente.");
  }
  if (trainer.situacaoProfissional !== "DISPONIVEL") {
    throw new AppError(
      "permission-denied",
      "Só é possível cadastrar exercícios com a situação profissional " +
        "DISPONIVEL."
    );
  }

  const [cavalo] = await Promise.all([
    input.cavaloId ? resolveLinkedHorse(uid, input.cavaloId) : undefined,
    ensureExerciseIndexes(),
  ]);

  const now = new Date();
  const exercise: NewExercise = {
    _id: new ObjectId(),
    nome: input.nome,
    descricao: input.descricao,
    orientacoes: input.orientacoes,
    duracaoPadraoMinutos: input.duracaoPadraoMinutos,
    materiais: input.materiais,
    privacidade: input.privacidade,
    ...(cavalo && {cavalo}),
    ativo: true,
    imagens: [],
    videos: [],
    cadastrante: "TREINADOR",
    treinador: {_id: uid, codigo: trainer.codigo, nome: trainer.nome},
    criadoEm: now,
    atualizadoEm: now,
  };

  // A transação garante que o código sequencial só é consumido se o
  // exercício for gravado.
  const codigo = await runInTransaction((session) =>
    insertExercise(exercise, session)
  );

  return {id: exercise._id.toHexString(), codigo, nome: exercise.nome};
}
