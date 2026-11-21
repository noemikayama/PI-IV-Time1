// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: CPU fracionária (gcf_gen1) por instância, para caber na cota
// de CPU do Cloud Run em southamerica-east1 (20 vCPUs por projeto).
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Definição das opções padrão das funções callable.
// -----------------------------------------------------------------------------

import type {CallableOptions} from "firebase-functions/v2/https";
import {mongodbUriSecret, WEB_API_KEY} from "./environment";

// Opções das Cloud Functions callable.
export const defaultFunctionOptions: CallableOptions = {
  region: "southamerica-east1",
  secrets: [mongodbUriSecret, WEB_API_KEY],
  // A cota de CPU do Cloud Run na região é de 20 vCPUs por projeto e conta
  // toda instância ligada, inclusive ociosa. Com 1 vCPU por instância (o
  // padrão), 20 instâncias somadas entre todas as functions esgotam a cota.
  // 'gcf_gen1' usa a fração de CPU da 1ª geração (cerca de 1/6 de vCPU
  // com 256 MiB); em troca, cada instância atende uma requisição por vez.
  cpu: "gcf_gen1",
  maxInstances: 10,
};
