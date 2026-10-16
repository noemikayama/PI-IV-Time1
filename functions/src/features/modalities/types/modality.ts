// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Definição dos tipos de modalidade.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";

// Coleção 'modalidades'.
export type ModalityDocument = {
    _id: ObjectId;
    codigo: number;
    nome: string;
    descricao: string;
};

// Formato enviado ao app: o ObjectId vira string, pois o callable não o
// serializa.
export type Modality = {
    id: string;
    codigo: number;
    nome: string;
    descricao: string;
};
