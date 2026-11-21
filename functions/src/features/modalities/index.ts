// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da busca de modalidade usada pela feature de cavalos.
// Data: 21/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da consulta de modalidades por ID.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da função de listagem de modalidades.
// -----------------------------------------------------------------------------

export {getModalities} from "./handlers/getModalities";
export {findModalityById} from "./repositories/modalityRepository";
export type {ModalityDocument} from "./types";
export {findModalitiesByIds} from "./repositories/modalityRepository";
