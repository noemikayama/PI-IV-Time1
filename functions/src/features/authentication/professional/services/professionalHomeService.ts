// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
import {countActiveExercisesByProfessional} from "../../../exercises";
import {
  countProfessionalExecutions,
  countProfessionalFeedbacks,
  findDayRecordsByProfessional,
} from "../../../training";
import {HOME_LIST_LIMIT, toProgress, toRef} from "../../shared";
import {
  findProfessionalHomeSource,
} from "../repositories/professionalRepository";
import type {HomeTreinador} from "../types";

/** Monta os dados da home do treinador.
 * @param {string} uid UID do usuário.
 */
export async function getProfessionalHome(
  uid: string
): Promise<HomeTreinador> {
  const professional = await findProfessionalHomeSource(uid);
  if (!professional || professional.situacaoProfissional === "INATIVO") {
    throw new AppError("permission-denied", "Conta inativa ou inexistente.");
  }

  const periods = getPeriods();

  const [todayRecords, weekExecutions, weekFeedbacks, totalExercises] =
        await Promise.all([
          findDayRecordsByProfessional(uid, periods.day),
          countProfessionalExecutions(uid, periods.week),
          countProfessionalFeedbacks(uid, periods.week),
          countActiveExercisesByProfessional(uid),
        ]);

  return {
    tipoConta: "TREINADOR",
    nome: professional.nome,
    totalCavalos: professional.cavalos.length,
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
    cavalos: professional.cavalos.slice(0, HOME_LIST_LIMIT).map(toRef),
    clientes: professional.clientes.slice(0, HOME_LIST_LIMIT).map(toRef),
  };
}
