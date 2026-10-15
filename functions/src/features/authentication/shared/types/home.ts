// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Uso de import type e padronização do formato.
//
// Data: 14/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação de types auxiliares da home
// -----------------------------------------------------------------------------

import type {HomeResponsavel} from "../../guardian/types";
import type {HomeTreinador} from "../../professional/types";

// CANCELADO nunca aparece na home.
export type StatusRegistroHome =
  | "PLANEJADO"
  | "REALIZADO"
  | "PARCIAL"
  | "NAO_REALIZADO";

// Referência curta usada em "Meus cavalos", "Meus treinadores" e
// "Meus clientes".
export interface RefResumo {
    id: string;
    nome: string;
}

// Formato dos cards.
export interface Progresso {
    feitos: number;
    total: number;
}

export type HomeResult = HomeResponsavel | HomeTreinador;
