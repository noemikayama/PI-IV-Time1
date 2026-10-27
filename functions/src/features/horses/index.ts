// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do cadastro, da edição e da consulta de cavalos.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Interface pública da feature de cavalos.
// -----------------------------------------------------------------------------

export {findTrainersOfHorses} from "./repositories/horseRepository";
export type {HorseTrainerRef} from "./types";
export {registerHorse} from "./handlers/registerHorse";
export {updateHorse} from "./handlers/updateHorse";
export {getHorse} from "./handlers/getHorse";
