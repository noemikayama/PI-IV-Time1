// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Padronização do formato.
//
// Data: 14/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação dos mappers
// -----------------------------------------------------------------------------

import type {Progresso, RefResumo} from "../types/home";

// Itens por lista na home. o restante vem em "Mostrar tudo".
export const HOME_LIST_LIMIT = 5;

export const toProgress = (done: number, total: number): Progresso => ({
  feitos: done,
  total,
});

export const toRef = (item: {_id: unknown; nome: string}): RefResumo => ({
  id: String(item._id),
  nome: item.nome,
});
