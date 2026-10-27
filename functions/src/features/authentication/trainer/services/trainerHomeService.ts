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
// Alteração: Padronização do formato e imports pelos index.ts das features.
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do service da home do treinador
// -----------------------------------------------------------------------------

import {AppError} from "../../../../shared/errors/AppError";
import {getPeriods} from "../../../../shared/utils/dates";
import {countActiveExercisesByTrainer} from "../../../exercises";
import {
  countTrainerExecutions,
  countTrainerFeedbacks,
  findDayRecordsByTrainer,
} from "../../../training";
import {HOME_LIST_LIMIT, toProgress, toRef} from "../../shared";
import {
  findTrainerHomeSource,
} from "../repositories/trainerRepository";
import type {HomeTreinador} from "../types";

/** Monta os dados da home do treinador.
 * @param {string} uid UID do usuário.
 */
export async function getTrainerHome(
  uid: string
): Promise<HomeTreinador> {
  const trainer = await findTrainerHomeSource(uid);
  if (!trainer || trainer.situacaoProfissional === "INATIVO") {
    throw new AppError("permission-denied", "Conta inativa ou inexistente.");
  }

  const periods = getPeriods();

  const [todayRecords, weekExecutions, weekFeedbacks, totalExercises] =
        await Promise.all([
          findDayRecordsByTrainer(uid, periods.day),
          countTrainerExecutions(uid, periods.week),
          countTrainerFeedbacks(uid, periods.week),
          countActiveExercisesByTrainer(uid),
        ]);

  return {
    tipoConta: "TREINADOR",
    nome: trainer.nome,
    totalCavalos: trainer.cavalos.length,
    treinosDoDia: todayRecords.map((record) => ({
      registroId: String(record._id),
      nomeTreino: record.treinamento?.titulo ?? "",
      nomeCavalo: record.cavalo?.nome ?? "",
      nomePlano: record.plano?.titulo ?? "",
      status: record.status,
    })),
    feedbacksSemana: toProgress(
      weekFeedbacks.withFeedback,
      weekFeedbacks.executed
    ),
    treinosSemana: toProgress(weekExecutions.executed, weekExecutions.total),
    totalExercicios: totalExercises,
    cavalos: trainer.cavalos.slice(0, HOME_LIST_LIMIT).map(toRef),
    clientes: trainer.clientes.slice(0, HOME_LIST_LIMIT).map(toRef),
  };
}
