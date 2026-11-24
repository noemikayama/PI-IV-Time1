// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação da avaliação pelo treinador vinculado ao cavalo.
// Alteração: Verificação de acesso pelo helper central (horseAccess).
// Alteração: Regra TRAINER_ONLY definida aqui (antes em horses);
// referências convertidas por toRefView.
// Alteração: Conta conferida pela regra única (assertActiveAccount), antes
// das modalidades.
// Alteração: Regra da avaliação vinda de HORSE_RULES (horses), a mesma que
// calcula a permissão "Nova avaliação" do perfil.
// -----------------------------------------------------------------------------

import {ObjectId} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {AppError} from "../../../shared/errors/AppError";
import {ROLES} from "../../../shared/constants/roles";
import {
  assertActiveAccount,
  HORSE_RULES,
  loadHorseAccess,
  toRefView,
} from "../../horses";
import {findModalitiesByIds} from "../../modalities";
import {
  addEvaluationToHorse,
  ensureEvaluationIndexes,
  insertEvaluation,
} from "../repositories/evaluationRepository";
import type {
  EvaluationCreateInput,
  EvaluationDocument,
  EvaluationView,
} from "../types";

// Só o treinador vinculado ao cavalo avalia (DD 5.2).
/** Converte a avaliação gravada para o formato do app.
 * @param {EvaluationDocument} evaluation Avaliação gravada.
 * @return {EvaluationView} Avaliação no formato do app.
 */
function toEvaluationView(evaluation: EvaluationDocument): EvaluationView {
  return {
    id: evaluation._id.toHexString(),
    codigo: evaluation.codigo,
    cavalo: {
      id: evaluation.cavalo._id.toHexString(),
      codigo: evaluation.cavalo.codigo,
      nome: evaluation.cavalo.nome,
    },
    treinador: toRefView(evaluation.treinador),
    data: evaluation.data,
    condicionamentoFisicoObservado: evaluation.condicionamentoFisicoObservado,
    limitacoes: evaluation.limitacoes ?? null,
    dificuldades: evaluation.dificuldades ?? null,
    modalidades: evaluation.modalidades.map(toRefView),
    observacoes: evaluation.observacoes,
    criadoEm: evaluation.criadoEm.toISOString(),
  };
}

/** Busca as modalidades informadas, na ordem do pedido.
 * @param {ObjectId[]} ids _ids validados, sem repetição.
 * @return {Promise<Array>} Referências resumidas.
 */
async function resolveModalities(ids: ObjectId[]) {
  const found = await findModalitiesByIds(ids);
  const byId = new Map(found.map((item) => [item._id.toHexString(), item]));
  return ids.map((id) => {
    const modality = byId.get(id.toHexString());
    if (!modality) {
      throw new AppError("invalid-argument", "Modalidade não encontrada.");
    }
    return {_id: modality._id, codigo: modality.codigo, nome: modality.nome};
  });
}

/** Cria a avaliação (RF06001). Só o treinador vinculado ao cavalo avalia
 * (DD 5.2). A avaliação e o resumo em cavalos.avaliacoes são gravados na
 * mesma transação. Não há edição depois (RF06005).
 * @param {string} uid UID do treinador autenticado.
 * @param {EvaluationCreateInput} input Dados validados.
 * @return {Promise<EvaluationView>} Avaliação criada.
 */
export async function createHorseEvaluationService(
  uid: string,
  input: EvaluationCreateInput
): Promise<EvaluationView> {
  // A conta vem antes dos demais erros, como nas outras callables.
  const treinador = await assertActiveAccount(uid, ROLES.trainer);
  const [modalidades] = await Promise.all([
    resolveModalities(input.modalidadeIds),
    ensureEvaluationIndexes(),
  ]);

  const evaluation = await runInTransaction(async (session) => {
    const {horse} = await loadHorseAccess(
      input.cavaloId,
      uid,
      HORSE_RULES.criarAvaliacao,
      session
    );
    if (input.data < horse.dataNascimento) {
      throw new AppError(
        "invalid-argument",
        "A data da avaliação não pode ser anterior ao nascimento do cavalo."
      );
    }

    const now = new Date();
    const saved = await insertEvaluation(
      {
        _id: new ObjectId(),
        cavalo: {_id: horse._id, codigo: horse.codigo, nome: horse.nome},
        treinador,
        data: input.data,
        condicionamentoFisicoObservado: input.condicionamentoFisicoObservado,
        ...(input.limitacoes && {limitacoes: input.limitacoes}),
        ...(input.dificuldades && {dificuldades: input.dificuldades}),
        modalidades,
        observacoes: input.observacoes,
        criadoEm: now,
        atualizadoEm: now,
      },
      session
    );
    await addEvaluationToHorse(
      horse._id,
      {_id: saved._id, codigo: saved.codigo, data: saved.data, treinador},
      session
    );
    return saved;
  });

  return toEvaluationView(evaluation);
}
