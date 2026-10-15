// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 12/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação das funções necessárias para conexão ao firebase
// -----------------------------------------------------------------------------

import {getApps, initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {getStorage} from "firebase-admin/storage";

// Inicializa o Firebase Admin SDK apenas uma vez.
// A reutilização evita erros de inicialização duplicada.
export const apps = getApps();

export const app = apps.length > 0
    ? apps[0]
    : initializeApp();

// Os serviços compartilham a instância inicializada acima e as credenciais
// configuradas para o ambiente de execução do Firebase.
export const auth = getAuth(app);

// Configura o Cloud Storage.
export const storage = getStorage(app);
