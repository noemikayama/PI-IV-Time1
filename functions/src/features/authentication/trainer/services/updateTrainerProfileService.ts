// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Edição da situação profissional do treinador.
//
// Data: 29/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Edição do nome, das regiões e dos anexos do treinador.
// -----------------------------------------------------------------------------

import {logger} from "firebase-functions";
import {runInTransaction} from "../../../../shared/config/mongodb";
import {deleteObject} from "../../../../shared/config/storage";
import {AppError} from "../../../../shared/errors/AppError";
import {updateAuthDisplayName} from "../../shared";
import {MAX_SERVICE_REGIONS} from "../constants/serviceRegions";
import {
  renameTrainerRefs,
  updateTrainerProfileDocument,
} from "../repositories/trainerRepository";
import {
  assertOwnedPath,
  loadActiveTrainer,
  toAttachmentViews,
} from "./trainerAttachmentService";
import type {
  ServiceRegion,
  TrainerDocument,
  TrainerProfileChanges,
  UpdateTrainerProfileInput,
  UpdateTrainerProfileResult,
} from "../types";

/** Chave de comparação de uma região, sem diferenciar maiúsculas.
 * @param {ServiceRegion} region Região de atendimento.
 * @return {string} Chave da região.
 */
function regionKey(region: ServiceRegion): string {
  return [region.estado, region.cidade, region.complemento ?? ""]
    .join("|")
    .toLocaleLowerCase("pt-BR");
}

/** Remove e acrescenta regiões sobre a lista gravada, mantendo as demais na
 * ordem atual.
 * @param {ServiceRegion[]} current Regiões gravadas.
 * @param {Object} changes Regiões a adicionar e a remover.
 * @return {ServiceRegion[]} Lista final.
 */
function applyRegionChanges(
  current: ServiceRegion[],
  changes: NonNullable<UpdateTrainerProfileInput["regioesAtendimento"]>
): ServiceRegion[] {
  const currentKeys = new Set(current.map(regionKey));
  const removed = new Set<string>();
  for (const region of changes.remover) {
    const key = regionKey(region);
    if (!currentKeys.has(key)) {
      throw new AppError("not-found", "Região de atendimento não encontrada.");
    }
    removed.add(key);
  }

  const kept = current.filter((region) => !removed.has(regionKey(region)));
  const keptKeys = new Set(kept.map(regionKey));
  const addedKeys = new Set<string>();
  for (const region of changes.adicionar) {
    const key = regionKey(region);
    if (removed.has(key)) {
      throw new AppError(
        "invalid-argument",
        "A mesma região não pode ser adicionada e removida."
      );
    }
    if (keptKeys.has(key)) {
      throw new AppError(
        "invalid-argument",
        "Região de atendimento já cadastrada."
      );
    }
    if (addedKeys.has(key)) {
      throw new AppError(
        "invalid-argument",
        "Região de atendimento repetida na lista."
      );
    }
    addedKeys.add(key);
  }

  const regioes = [...kept, ...changes.adicionar];
  if (regioes.length > MAX_SERVICE_REGIONS) {
    throw new AppError(
      "invalid-argument",
      `Limite de ${MAX_SERVICE_REGIONS} regiões de atendimento atingido.`
    );
  }
  return regioes;
}

/** Confere as alterações com o documento atual. Nome ou situação igual ao
 * gravado não é alteração; anexo ou região inexistente gera erro.
 * @param {TrainerDocument} trainer Treinador lido na transação.
 * @param {UpdateTrainerProfileInput} input Alterações validadas.
 * @return {TrainerProfileChanges} Alterações a gravar.
 */
function resolveChanges(
  trainer: TrainerDocument,
  input: UpdateTrainerProfileInput
): TrainerProfileChanges {
  const removerCertificacoes = input.certificacoes?.remover ?? [];
  const missingFile =
    (input.experiencias &&
      trainer.experiencias !== input.experiencias.remover) ||
    removerCertificacoes.some(
      (caminho) => !trainer.certificacoes.includes(caminho)
    );
  if (missingFile) {
    throw new AppError("not-found", "Anexo não encontrado.");
  }

  return {
    nome: input.nome !== trainer.nome ? input.nome : undefined,
    situacaoProfissional:
      input.situacaoProfissional !== trainer.situacaoProfissional ?
        input.situacaoProfissional :
        undefined,
    regioesAtendimento: input.regioesAtendimento &&
      applyRegionChanges(trainer.regioesAtendimento, input.regioesAtendimento),
    removerExperiencia: input.experiencias?.remover,
    removerCertificacoes,
  };
}

/** Indica se há algo a gravar.
 * @param {TrainerProfileChanges} changes Alterações conferidas.
 * @return {boolean} Se alguma alteração foi pedida.
 */
function hasChanges(changes: TrainerProfileChanges): boolean {
  return changes.nome !== undefined ||
    changes.situacaoProfissional !== undefined ||
    changes.regioesAtendimento !== undefined ||
    changes.removerExperiencia !== undefined ||
    changes.removerCertificacoes.length > 0;
}

/** Remove do Storage os PDFs cuja referência já foi apagada no MongoDB.
 * A falha não desfaz a edição: o arquivo fica sem referência e é registrado.
 * @param {string} uid UID do usuário.
 * @param {string[]} caminhos Caminhos dos arquivos.
 */
async function deleteRemovedFiles(
  uid: string,
  caminhos: string[]
): Promise<void> {
  await Promise.all(
    caminhos.map(async (caminho) => {
      try {
        await deleteObject(caminho);
      } catch {
        logger.error("Falha ao remover anexo do Storage", {uid, caminho});
      }
    })
  );
}

/** Altera o nome, a situação profissional e as regiões de atendimento e
 * remove anexos do treinador.
 * A senha tem fluxo próprio (requestPasswordReset) e o envio de PDFs usa
 * createTrainerAttachmentUpload/confirmTrainerAttachment.
 * @param {string} uid UID do usuário autenticado.
 * @param {UpdateTrainerProfileInput} input Alterações validadas.
 * @return {Promise<UpdateTrainerProfileResult>} Campos editáveis atualizados.
 */
export async function updateTrainerProfileService(
  uid: string,
  input: UpdateTrainerProfileInput
): Promise<UpdateTrainerProfileResult> {
  // Só aceita os caminhos que o servidor gera para o próprio usuário.
  if (input.experiencias) {
    assertOwnedPath(uid, "experiencias", input.experiencias.remover);
  }
  for (const caminho of input.certificacoes?.remover ?? []) {
    assertOwnedPath(uid, "certificacoes", caminho);
  }

  // Leitura e gravação na mesma transação: as listas são recalculadas sobre o
  // documento atual e uma escrita concorrente faz a transação ser refeita.
  const {trainer, changes} = await runInTransaction(async (session) => {
    const current = await loadActiveTrainer(uid, session);
    const resolved = resolveChanges(current, input);
    // Nada mudou: nada é gravado e 'atualizadoEm' é mantido.
    if (!hasChanges(resolved)) return {trainer: current, changes: resolved};

    const updated = await updateTrainerProfileDocument(
      uid,
      resolved,
      new Date(),
      session
    );
    // A leitura acima está na mesma transação; o filtro do update só
    // falharia com uma escrita concorrente, que faz a transação ser refeita.
    if (!updated) {
      throw new AppError("permission-denied", "Cadastro inativo.");
    }
    // O nome é copiado em cavalos (treinadores/avaliacoes),
    // registros_treino e exercicios.
    if (resolved.nome !== undefined) {
      await renameTrainerRefs(uid, updated.nome, session);
    }
    return {trainer: updated, changes: resolved};
  });

  // Efeitos fora do MongoDB só depois da confirmação da transação.
  if (changes.nome !== undefined) {
    await updateAuthDisplayName(uid, trainer.nome);
  }
  // O app só envia novos PDFs depois desta resposta (ver contrato): um índice
  // liberado aqui não é reaproveitado antes da remoção do arquivo.
  await deleteRemovedFiles(uid, [
    ...(changes.removerExperiencia !== undefined ?
      [changes.removerExperiencia] :
      []),
    ...changes.removerCertificacoes,
  ]);

  return {
    nome: trainer.nome,
    situacaoProfissional: trainer.situacaoProfissional,
    ...(await toAttachmentViews(trainer)),
    regioesAtendimento: trainer.regioesAtendimento,
    atualizadoEm: trainer.atualizadoEm.toISOString(),
  };
}
