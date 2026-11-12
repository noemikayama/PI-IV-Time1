// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cadastro de exercícios genéricos e específicos pelo treinador.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {findTrainerById} from "../../authentication/trainer";
import {findActiveHorseById} from "../../horses";
import {
  ensureExerciseIndexes,
  insertExercise,
} from "../repositories/exerciseRepository";
import type {
  ExerciseHorseRef,
  ExerciseRegistrationInput,
  ExerciseRegistrationResult,
  NewExercise,
} from "../types";

/** Confere se o cavalo está ativo e vinculado ao treinador e monta a
 * referência resumida gravada no exercício.
 * @param {string} uid UID do treinador.
 * @param {ObjectId} id _id do cavalo.
 * @return {Promise<ExerciseHorseRef>} Referência resumida do cavalo.
 */
async function resolveLinkedHorse(
  uid: string,
  id: ObjectId
): Promise<ExerciseHorseRef> {
  const horse = await findActiveHorseById(id);
  if (!horse) throw new AppError("not-found", "Cavalo não encontrado.");
  if (!horse.treinadores.some((trainer) => trainer._id === uid)) {
    throw new AppError(
      "permission-denied",
      "Você não tem vínculo com este cavalo."
    );
  }
  return {_id: horse._id, codigo: horse.codigo, nome: horse.nome};
}

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
