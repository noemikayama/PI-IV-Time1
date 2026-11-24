// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Endereço (MICROCHIP_HOST) e porta (MICROCHIP_PORTA) do servidor
// Java de validação de microchip.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Alterei a WEB_API_KEY para secrets
//
// Data: 14/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Adição da WEB_API_KEY
//
// Data: 12/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Acesso às variáveis de ambiente referentes ao MongoDB.
// -----------------------------------------------------------------------------

import {
  defineInt,
  defineSecret,
  defineString,
} from "firebase-functions/params";

// O URI é tratado como segredo; o nome do banco é um parâmetro de ambiente
// comum, ambos vinculados ao ambiente da Cloud Function.
// Parâmetros declarados explicitamente para o deploy das Cloud Functions.
// Funções que usam o secret precisam listá-lo em
// 'secrets: [mongodbUriSecret]'
export const mongodbUriSecret = defineSecret("MONGODB_URI");
export const mongodbDbParam = defineString("MONGODB_DB");

export type Environment = {
    mongodbUri: string;
    mongodbDb: string;
};

// Garante que o valor existe e não é vazio, sem expô-lo em mensagens de
// erro.
/** Valida e normaliza um valor obrigatório de configuração.
 * @param {string} name Nome da variável.
 * @param {string|undefined} value Valor configurado.
 * @return {string} Valor normalizado.
 */
function requireValue(name: string, value: string | undefined): string {
  const trimmed = value?.trim();

  if (!trimmed) {
    throw new Error(
      `Variável de ambiente ${name} inválida ou não definida.`
    );
  }

  return trimmed;
}

/** Lê e valida as configurações de ambiente da aplicação.
 * @return {Environment} Configurações validadas.
 */
export function getEnv(): Environment {
  // A leitura é feita no momento do uso para validar os valores fornecidos
  // pelo ambiente sem armazenar cópias globais das configurações.
  return {
    mongodbUri: requireValue("MONGODB_URI", mongodbUriSecret.value()),
    mongodbDb: requireValue("MONGODB_DB", mongodbDbParam.value()),
  };
}

// Secrets da chave da API
export const WEB_API_KEY = defineSecret("WEB_API_KEY");

// Servidor Java de validação de microchip. Vazio (o padrão) desliga a
// consulta ao Java: só o .env.local do emulador define o endereço, porque o
// servidor roda na máquina local, ao lado do emulador.
export const microchipHostParam = defineString("MICROCHIP_HOST", {
  default: "",
  description: "Endereço do servidor Java de microchip. Deixe vazio para " +
    "não consultar o Java (só o formato de 15 dígitos é conferido).",
});
export const microchipPortParam = defineInt("MICROCHIP_PORTA", {
  default: 7700,
  description: "Porta TCP do servidor Java de microchip.",
});
