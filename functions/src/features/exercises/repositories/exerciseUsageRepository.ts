// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Consulta se o exercício foi planejado para algum dos cavalos
// (planos e registros de treino), usada pelo acesso ao exercício.
// -----------------------------------------------------------------------------

// Coleções 'planos' e 'registros_treino', só leitura, como no dashboard.
// Índices: idx_planos_cavalo_status e idx_registros_cavalo_data (os dois com
// prefixo cavalo._id). As coleções são lidas sem tipo: importar os tipos de
// plans e training exigiria tipos que elas não exportam, e um import de
// verdade criaria um ciclo, porque essas features importam exercises.
import type {ObjectId} from "mongodb";
import {getDatabase} from "../../../shared/config/mongodb";
import {COLLECTIONS} from "../../../shared/constants/collections";
import {ensureIndexesOnce} from "../../../shared/database/indexes";

// Cópias exatas das declarações de plans (PLAN_INDEXES) e training
// (RECORD_INDEXES): com a mesma chave e o mesmo nome, o createIndexes não
// faz nada se o índice já existe. Garantir aqui evita varrer as coleções
// enquanto nenhum plano foi cadastrado depois do deploy. Se a declaração
// mudar lá, mude aqui também.
const ensureUsageIndexes = (): Promise<void[]> => Promise.all([
  ensureIndexesOnce(COLLECTIONS.Planos, [
    {key: {"cavalo._id": 1, "status": 1}, name: "idx_planos_cavalo_status"},
  ]),
  ensureIndexesOnce(COLLECTIONS.RegistrosTreino, [
    {
      key: {"cavalo._id": 1, "dataPlanejada": 1, "status": 1},
      name: "idx_registros_cavalo_data",
    },
  ]),
]);

/** Diz se o exercício aparece em algum plano (de qualquer situação) ou
 * registro de treino de algum dos cavalos. Começa pelos planos, que são
 * poucos por cavalo. Os registros cobrem o exercício que a edição de um
 * treinamento tirou do plano, mas que continua nos dias já agendados.
 * @param {ObjectId} exerciseId _id do exercício.
 * @param {ObjectId[]} horseIds _id dos cavalos de quem consulta.
 * @return {Promise<boolean>} Se o exercício foi planejado para algum deles.
 */
export async function isExercisePlannedForHorses(
  exerciseId: ObjectId,
  horseIds: ObjectId[]
): Promise<boolean> {
  // Sem cavalo vinculado, nada a procurar: nem abre conexão.
  if (horseIds.length === 0) return false;

  const [db] = await Promise.all([getDatabase(), ensureUsageIndexes()]);
  const inPlan = await db.collection(COLLECTIONS.Planos).findOne(
    {
      "cavalo._id": {$in: horseIds},
      "planejamento.treinamento.exercicios._id": exerciseId,
    },
    {projection: {_id: 1}}
  );
  if (inPlan) return true;

  const inRecord = await db.collection(COLLECTIONS.RegistrosTreino).findOne(
    {
      "cavalo._id": {$in: horseIds},
      "exercicios.exercicio._id": exerciseId,
    },
    {projection: {_id: 1}}
  );
  return inRecord !== null;
}
