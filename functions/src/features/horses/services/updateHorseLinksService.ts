// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 04/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Regra do autor do plano ativo movida para
// assertTrainersCanLeave.ts (também usada no desvínculo).
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Vínculo do atleta e do treinador pelo e-mail.
// Alteração: Recálculo dos clientes movido para trainerClients.ts.
// Alteração: Verificação de acesso pelo helper central (horseAccess).
// Alteração: Listas resumidas via horseSummaryRepository.ts; autor do
// plano ativo consultado na feature training.
// Alteração: Busca da conta pelo e-mail unificada em resolveLinkedAccount.
// Alteração: Conta vinculada conferida pela regra única de horseAccess.ts.
// Alteração: Devolve o perfil atualizado (HorseProfile).
// -----------------------------------------------------------------------------

import type {ClientSession} from "mongodb";
import {runInTransaction} from "../../../shared/config/mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import {findEmail} from "../../authentication/shared";
import type {AccountType} from "../../authentication/shared";
import {
  addHorseToGuardian,
  addHorseToTrainer,
  removeGuardianResponsibility,
  removeHorseFromTrainer,
} from "../repositories/horseSummaryRepository";
import {
  ensureHorseIndexes,
  updateHorseDocument,
} from "../repositories/horseRepository";
import type {
  AccountRef,
  HorseDocument,
  HorseLinksInput,
  HorseProfile,
  TrainerHorseRef,
} from "../types";
import {assertTrainersCanLeave} from "./assertTrainersCanLeave";
import {
  assertActiveAccount,
  findActiveGuardian,
  findActiveTrainer,
  HORSE_RULES,
  loadHorseAccess,
} from "./horseAccess";
import {buildHorseProfile} from "./horseProfile";
import {syncTrainerClients} from "./trainerClients";

// O que muda entre os dois vínculos feitos por e-mail: o tipo de conta
// exigido, os textos das mensagens e a busca da conta ativa (regra única em
// horseAccess.ts).
const LINKED_ACCOUNTS = {
  RESPONSAVEL: {
    vinculo: "atleta",
    outroTipo: "um treinador",
    findActive: findActiveGuardian,
  },
  TREINADOR: {
    vinculo: "treinador",
    outroTipo: "um responsável",
    findActive: findActiveTrainer,
  },
} as const;

/** Busca a conta dona do e-mail informado para o vínculo: um responsável
 * para o atleta (pode ser o próprio proprietário) ou um treinador.
 * @param {string} email E-mail normalizado.
 * @param {AccountType} tipoConta Tipo de conta exigido pelo vínculo.
 * @return {Promise<AccountRef>} Referência resumida da conta.
 */
async function resolveLinkedAccount(
  email: string,
  tipoConta: AccountType
): Promise<AccountRef> {
  const {vinculo, outroTipo, findActive} = LINKED_ACCOUNTS[tipoConta];
  const reservation = await findEmail(email);
  if (!reservation) {
    throw new AppError(
      "not-found",
      `Nenhuma conta encontrada com o e-mail informado para o ${vinculo}.`
    );
  }
  if (reservation.tipoConta !== tipoConta) {
    throw new AppError(
      "invalid-argument",
      `O e-mail informado para o ${vinculo} pertence a ${outroTipo}.`
    );
  }
  const account = await findActive(reservation.usuarioId);
  if (!account) {
    throw new AppError(
      "failed-precondition",
      `A conta do ${vinculo} está inativa.`
    );
  }
  return account;
}

/** Troca o atleta: atualiza responsaveis.cavalos do antigo e do novo.
 * @param {HorseDocument} horse Cavalo lido na transação.
 * @param {AccountRef} athlete Novo atleta.
 * @param {ClientSession} session Sessão da transação.
 */
async function relinkAthlete(
  horse: HorseDocument,
  athlete: AccountRef,
  session: ClientSession
): Promise<void> {
  const ref: TrainerHorseRef = {
    _id: horse._id,
    codigo: horse.codigo,
    nome: horse.nome,
  };
  if (horse.atleta) {
    await removeGuardianResponsibility(
      horse.atleta._id,
      horse._id,
      "ATLETA",
      session
    );
  }
  // O atleta foi conferido antes da transação; false aqui só ocorre se a
  // conta foi desativada nesse meio-tempo, e lançar desfaz o vínculo todo.
  if (!(await addHorseToGuardian(athlete._id, ref, ["ATLETA"], session))) {
    throw new AppError(
      "failed-precondition",
      "A conta do atleta está inativa."
    );
  }
}

/** Troca o treinador: o cavalo tem um único treinador. Recusa a troca se
 * um treinador que sai for autor do plano ATIVO do cavalo (RF05003).
 * @param {HorseDocument} horse Cavalo lido na transação.
 * @param {AccountRef} trainer Novo treinador.
 * @param {ClientSession} session Sessão da transação.
 * @return {Promise<string[]>} UIDs dos treinadores que saíram.
 */
async function relinkTrainer(
  horse: HorseDocument,
  trainer: AccountRef,
  session: ClientSession
): Promise<string[]> {
  const leaving = horse.treinadores.filter((item) => item._id !== trainer._id);
  await assertTrainersCanLeave(horse._id, leaving, session);

  for (const old of leaving) {
    await removeHorseFromTrainer(old._id, horse._id, session);
  }
  await addHorseToTrainer(
    trainer._id,
    {_id: horse._id, codigo: horse.codigo, nome: horse.nome},
    session
  );
  return leaving.map((old) => old._id);
}

/** Vincula o atleta e/ou o treinador informados pelo e-mail. O vínculo é
 * imediato, sem aceite (RF05007), e substitui o anterior. Cavalo, listas
 * resumidas e clientes dos treinadores mudam na mesma transação.
 * @param {string} uid UID do proprietário autenticado.
 * @param {HorseLinksInput} input Dados validados.
 * @return {Promise<HorseProfile>} Perfil atualizado.
 */
export async function updateHorseLinksService(
  uid: string,
  input: HorseLinksInput
): Promise<HorseProfile> {
  const [athlete, trainer] = await Promise.all([
    input.emailAtleta ?
      resolveLinkedAccount(input.emailAtleta, "RESPONSAVEL") :
      undefined,
    input.emailTreinador ?
      resolveLinkedAccount(input.emailTreinador, "TREINADOR") :
      undefined,
    assertActiveAccount(uid, ROLES.guardian),
    // idx_cavalos_treinadores sustenta o recálculo dos clientes.
    ensureHorseIndexes(),
  ]);

  const updated = await runInTransaction(async (session) => {
    const {horse} = await loadHorseAccess(
      input.id,
      uid,
      HORSE_RULES.gerenciarVinculos,
      session
    );

    const now = new Date();
    const changes: Partial<Pick<HorseDocument, "atleta" | "treinadores">> =
      {};
    // Treinadores cujos clientes precisam ser recalculados.
    const affected = new Set<string>();

    if (athlete && horse.atleta?._id !== athlete._id) {
      await relinkAthlete(horse, athlete, session);
      changes.atleta = {...athlete, vinculadoEm: now};
      horse.treinadores.forEach((item) => affected.add(item._id));
    }

    const current = horse.treinadores;
    const sameTrainer =
      current.length === 1 && current[0]._id === trainer?._id;
    if (trainer && !sameTrainer) {
      const leaving = await relinkTrainer(horse, trainer, session);
      const kept = current.find((item) => item._id === trainer._id);
      changes.treinadores = [
        {...trainer, vinculadoEm: kept?.vinculadoEm ?? now},
      ];
      [...leaving, trainer._id].forEach((id) => affected.add(id));
    }

    if (Object.keys(changes).length === 0) return horse;

    const result = await updateHorseDocument(
      horse._id,
      {$set: {...changes, atualizadoEm: now}},
      session
    );
    // Depois de gravar o cavalo: os clientes são derivados de 'cavalos'.
    for (const trainerId of affected) {
      await syncTrainerClients(trainerId, session);
    }
    return result;
  });

  if (!updated) {
    throw new AppError("not-found", "Cavalo não encontrado.");
  }
  return buildHorseProfile(updated, uid);
}
