// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Exportação dos cavalos vinculados a uma pessoa, usados pelo
// acesso ao exercício.
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Exportação da conferência do microchip no servidor Java.
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportações usadas pela feature de planos.
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da consulta do cavalo ativo, usada pelo cadastro de
// exercícios.
//
// Data: 04/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do desvínculo de atleta ou treinador.
//
// Data: 03/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: getHorseProfile substitui getHorse e getHorseCurrentPlan;
// HORSE_RULES exportado para a avaliação; getHorseForUser, HorseAccessRule
// e HorseRelation deixam a superfície pública (sem uso fora de horses).
// Alteração: Exportação dos vínculos e da lista de cavalos.
// Alteração: Exportação da inclusão de saúde, da exclusão e do plano atual;
// consulta do cavalo, relação e conta ativa para a feature de avaliações.
// Alteração: Exportação do helper central de acesso ao cavalo.
// Alteração: Exportação dos tipos dos itens das listas resumidas.
// Alteração: Superfície pública reduzida ao que outras features usam
// (getHorseForUser, loadHorseAccess, toRefView e HorseAccessRule).
// Alteração: Exportação de assertActiveAccount para a avaliação.
//
// Data: 27/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do envio, da confirmação e da remoção de imagens.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do cadastro, da edição e da consulta de cavalos.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Interface pública da feature de cavalos.
// -----------------------------------------------------------------------------

export {
  findActiveHorseById,
  findLinkedHorseIds,
  findTrainersOfHorses,
  updateHorseDocument,
} from "./repositories/horseRepository";
export {
  assertActiveAccount,
  getHorseForUser,
  HORSE_RULES,
  loadHorseAccess,
} from "./services/horseAccess";
export {toRefView} from "./services/horseMappers";
export type {
  AccountRef,
  GuardianHorseRef,
  HorseDocument,
  HorseTrainerRef,
  RefView,
  TrainerHorseRef,
} from "./types";
export {registerHorse} from "./handlers/registerHorse";
export {validateMicrochip} from "./handlers/validateMicrochip";
export {updateHorse} from "./handlers/updateHorse";
export {getHorseProfile} from "./handlers/getHorseProfile";
export {listHorses} from "./handlers/listHorses";
export {updateHorseLinks} from "./handlers/updateHorseLinks";
export {removeHorseLink} from "./handlers/removeHorseLink";
export {addHorseHealthEntry} from "./handlers/addHorseHealthEntry";
export {deleteHorse} from "./handlers/deleteHorse";
export {createHorseImageUpload} from "./handlers/createHorseImageUpload";
export {confirmHorseImage} from "./handlers/confirmHorseImage";
export {removeHorseImage} from "./handlers/removeHorseImage";
