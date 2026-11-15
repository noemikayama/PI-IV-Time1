// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 02/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conferência da conta ativa antes das operações com cavalos.
// Alteração: Resolução central da relação do usuário com o cavalo e da
// permissão de cada operação.
// Alteração: getHorseForUser (conta + cavalo + acesso fora de transação);
// regra das avaliações (TRAINER_ONLY) movida para a feature evaluations.
// Alteração: Regra única de conta ativa (findActiveGuardian e
// findActiveTrainer), lida só com código, nome e situação; assertActiveAccount
// devolve a conta.
// Alteração: Regras de cada operação reunidas em HORSE_RULES (inclusive a
// da avaliação, de volta de evaluations), usadas tanto para barrar a
// operação quanto para as permissões do perfil; inclusão de saúde passa a
// ser exclusiva do proprietário.
// -----------------------------------------------------------------------------

import type {ClientSession, ObjectId} from "mongodb";
import {ROLES} from "../../../shared/constants/roles";
import {AppError} from "../../../shared/errors/AppError";
import type {
  AuthenticatedUser,
} from "../../../shared/middleware/requireAuthentication";
// Import direto dos repositories, como no cadastro: os index.ts de
// authentication alcançam a home, que importa esta feature.
import {
  findGuardianAccount,
} from "../../authentication/guardian/repositories/guardianRepository";
import {
  findTrainerAccount,
} from "../../authentication/trainer/repositories/trainerRepository";
import {findActiveHorseById} from "../repositories/horseRepository";
import type {AccountRef, HorseDocument, HorseRelation} from "../types";

// Relações aceitas por uma operação e a mensagem para quem tem vínculo com
// o cavalo, mas não a relação exigida.
export type HorseAccessRule = {
    allowed: readonly HorseRelation[];
    deniedMessage: string;
};

/** Regra das operações exclusivas do proprietário.
 * @param {string} action Ação usada na mensagem ("editar o cavalo").
 * @return {HorseAccessRule} Regra de acesso.
 */
const ownerOnly = (action: string): HorseAccessRule => ({
  allowed: ["PROPRIETARIO"],
  deniedMessage: `Apenas o proprietário pode ${action}.`,
});

// Fonte única da matriz de permissões do cavalo: as callables barram por
// estas regras e o perfil calcula as permissões exibidas a partir delas.
// Consultar não tem regra: qualquer vínculo com o cavalo consulta.
export const HORSE_RULES = {
  editar: ownerOnly("editar o cavalo"),
  alterarImagens: ownerOnly("alterar as imagens do cavalo"),
  adicionarSaude: ownerOnly("incluir informações de saúde"),
  excluir: ownerOnly("excluir o cavalo"),
  gerenciarVinculos: ownerOnly("alterar os vínculos do cavalo"),
  criarAvaliacao: {
    allowed: ["TREINADOR"],
    deniedMessage: "Apenas o treinador vinculado pode avaliar o cavalo.",
  },
} as const satisfies Record<string, HorseAccessRule>;

/** Se alguma das relações de quem chama é aceita pela regra.
 * @param {HorseRelation[]} relations Relação de quem chama com o cavalo.
 * @param {HorseAccessRule} rule Regra da operação.
 * @return {boolean} Se a operação é permitida.
 */
export const isAllowed = (
  relations: readonly HorseRelation[],
  rule: HorseAccessRule
): boolean => relations.some((relation) => rule.allowed.includes(relation));

export type HorseAccess = {
    horse: HorseDocument;
    // Relação de quem chama: PROPRIETARIO e/ou ATLETA, ou TREINADOR.
    relations: HorseRelation[];
};

/** Relação do usuário com o cavalo. Vazia para quem não tem vínculo.
 * @param {HorseDocument} horse Documento do cavalo.
 * @param {string} uid UID do usuário.
 * @return {HorseRelation[]} PROPRIETARIO e/ou ATLETA, ou TREINADOR.
 */
export function relationsOf(
  horse: Pick<HorseDocument, "proprietario" | "atleta" | "treinadores">,
  uid: string
): HorseRelation[] {
  const result: HorseRelation[] = [];
  if (horse.proprietario._id === uid) result.push("PROPRIETARIO");
  if (horse.atleta?._id === uid) result.push("ATLETA");
  if (horse.treinadores.some((trainer) => trainer._id === uid)) {
    result.push("TREINADOR");
  }
  return result;
}

/** Confere o acesso ao cavalo já lido. Cavalo inexistente, inativo ou sem
 * vínculo com o usuário é tratado como inexistente ('not-found'), para não
 * revelar cavalos de terceiros. Quem tem vínculo, mas não a relação exigida
 * pela regra, recebe 'permission-denied'. Sem regra, qualquer vínculo vale.
 * @param {HorseDocument|null} horse Cavalo lido (ativo) ou null.
 * @param {string} uid UID do usuário.
 * @param {HorseAccessRule} rule Relações aceitas pela operação.
 * @return {HorseAccess} Cavalo e relação de quem chama.
 */
export function resolveHorseAccess(
  horse: HorseDocument | null,
  uid: string,
  rule?: HorseAccessRule
): HorseAccess {
  const relations = horse ? relationsOf(horse, uid) : [];
  if (!horse || relations.length === 0) {
    throw new AppError("not-found", "Cavalo não encontrado.");
  }
  if (rule && !isAllowed(relations, rule)) {
    throw new AppError("permission-denied", rule.deniedMessage);
  }
  return {horse, relations};
}

/** Lê o cavalo ativo e confere o acesso. Dentro de uma transação, passe a
 * sessão para que a leitura faça parte dela.
 * @param {ObjectId} id _id do cavalo.
 * @param {string} uid UID do usuário.
 * @param {HorseAccessRule} rule Relações aceitas pela operação.
 * @param {ClientSession} session Sessão da transação, se houver.
 * @return {Promise<HorseAccess>} Cavalo e relação de quem chama.
 */
export async function loadHorseAccess(
  id: ObjectId,
  uid: string,
  rule?: HorseAccessRule,
  session?: ClientSession
): Promise<HorseAccess> {
  return resolveHorseAccess(await findActiveHorseById(id, session), uid, rule);
}

/** Leitura fora de transação: confere a conta e lê o cavalo em paralelo e
 * depois o acesso. Conta inativa sempre prevalece, porque a leitura do
 * cavalo nunca falha (devolve null).
 * @param {AuthenticatedUser} user Usuário autenticado (uid e papel).
 * @param {ObjectId} id _id do cavalo.
 * @param {HorseAccessRule} rule Relações aceitas pela operação.
 * @return {Promise<HorseAccess>} Cavalo e relação de quem chama.
 */
export async function getHorseForUser(
  user: AuthenticatedUser,
  id: ObjectId,
  rule?: HorseAccessRule
): Promise<HorseAccess> {
  const [horse] = await Promise.all([
    findActiveHorseById(id),
    assertActiveAccount(user.uid, user.role),
  ]);
  return resolveHorseAccess(horse, user.uid, rule);
}

/** Responsável com cadastro ATIVO, como referência resumida.
 * @param {string} uid UID do responsável.
 * @return {Promise<AccountRef|null>} Conta, ou null se inativa/inexistente.
 */
export async function findActiveGuardian(
  uid: string
): Promise<AccountRef | null> {
  const guardian = await findGuardianAccount(uid);
  return guardian?.situacaoCadastral === "ATIVO" ?
    {_id: guardian._id, codigo: guardian.codigo, nome: guardian.nome} :
    null;
}

/** Treinador fora de INATIVO (afastado ou indisponível ainda acessa),
 * como referência resumida.
 * @param {string} uid UID do treinador.
 * @return {Promise<AccountRef|null>} Conta, ou null se inativa/inexistente.
 */
export async function findActiveTrainer(
  uid: string
): Promise<AccountRef | null> {
  const trainer = await findTrainerAccount(uid);
  return trainer && trainer.situacaoProfissional !== "INATIVO" ?
    {_id: trainer._id, codigo: trainer.codigo, nome: trainer.nome} :
    null;
}

/** Garante que a conta existe e está ativa, como na home e no dashboard, e
 * a devolve como referência resumida (usada no cadastro e na avaliação).
 * Qualquer papel que não seja responsável ou treinador é recusado.
 * @param {string} uid UID do usuário autenticado.
 * @param {string} role Papel do token ('guardian' ou 'trainer').
 * @return {Promise<AccountRef>} Conta ativa.
 */
export async function assertActiveAccount(
  uid: string,
  role: string | undefined
): Promise<AccountRef> {
  let account: AccountRef | null = null;
  if (role === ROLES.guardian) account = await findActiveGuardian(uid);
  else if (role === ROLES.trainer) account = await findActiveTrainer(uid);
  if (!account) {
    throw new AppError("permission-denied", "Conta inativa ou inexistente.");
  }
  return account;
}
