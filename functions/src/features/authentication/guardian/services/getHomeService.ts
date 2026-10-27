// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do service da home do responsável.
// -----------------------------------------------------------------------------

import {AppError} from "../../../../shared/errors/AppError";
import {getPeriods} from "../../../../shared/utils/dates";
import {findTrainersOfHorses} from "../../../horses";
import {countHorseExecutions, findDayRecordsByHorses} from "../../../training";
import {HOME_LIST_LIMIT, toProgress, toRef} from "../../shared";
import {findGuardianHomeSource} from "../repositories/guardianRepository";
import type {HomeResponsavel} from "../types";

/** Monta os dados da home do responsável.
 * @param {string} uid UID do usuário.
 */
export async function getGuardianHome(
  uid: string
): Promise<HomeResponsavel> {
  const guardian = await findGuardianHomeSource(uid);
  if (!guardian || guardian.situacaoCadastral !== "ATIVO") {
    throw new AppError("permission-denied", "Conta inativa ou inexistente.");
  }

  const horseIds = guardian.cavalos.map((horse) => horse._id);
  const periods = getPeriods();

  const [todayRecords, executions, trainers] = await Promise.all([
    findDayRecordsByHorses(horseIds, periods.day),
    countHorseExecutions(horseIds, periods.week, periods.month),
    // Treinadores não ficam em responsaveis.cavalos: vêm dos cavalos.
    findTrainersOfHorses(horseIds, HOME_LIST_LIMIT),
  ]);

  return {
    tipoConta: "RESPONSAVEL",
    nome: guardian.nome,
    totalCavalos: guardian.cavalos.length,
    treinosDoDia: todayRecords.map((record) => ({
      registroId: String(record._id),
      nomeTreino: record.treinamento?.titulo ?? "",
      nomeCavalo: record.cavalo?.nome ?? "",
      nomeTreinador: record.treinador?.nome ?? "",
      duracaoMinutos: record.treinamento?.duracaoEstimadaMinutos ?? 0,
      nomePlano: record.plano?.titulo ?? "",
      status: record.status,
    })),
    treinosSemana: toProgress(
      executions.week.executed,
      executions.week.total
    ),
    treinosMes: toProgress(executions.month.executed, executions.month.total),
    treinosTotal: executions.allTimeExecuted,
    cavalos: guardian.cavalos.slice(0, HOME_LIST_LIMIT).map(toRef),
    treinadores: trainers.map(toRef),
  };
}
