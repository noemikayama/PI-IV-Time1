// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 12/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação das funções necessárias para acesso das variáveis de
// ambientes referentes ao mongo
// ----------------------------------------------------------------------------- 

import {defineSecret, defineString} from "firebase-functions/params";

// O URI é tratado como segredo; o nome do banco é um parâmetro de configuração
// comum, ambos vinculados ao ambiente da Cloud Function.
// Parâmetros declarados explicitamente para o deploy das Cloud Functions.
// Funções que usam o secret precisam listá-lo em 'secrets: [mongodbUriSecret]'
export const mongodbUriSecret = defineSecret("MONGODB_URI");
export const mongodbDbParam = defineString("MONGODB_DB");

export type Environment = {
    mongodbUri: string;
    mongodbDb: string;
};

// Garante que o valor existe e não é vazio, sem exposição em mensagens de erro.
function requireValue(name: string, value: string | undefined): string {
    const trimmed = value?.trim();

    if (!trimmed) {
        throw new Error(`Variável de ambiente ${name} inválida ou não definida.`);
    }

    return trimmed;
}

export function getEnv(): Environment {
    // A leitura é feita no momento do uso para validar os valores fornecidos
    // pelo ambiente sem armazenar cópias globais das configurações.
    return {
        mongodbUri: requireValue("MONGODB_URI", mongodbUriSecret.value()),
        mongodbDb: requireValue("MONGODB_DB", mongodbDbParam.value()),
    };
}
