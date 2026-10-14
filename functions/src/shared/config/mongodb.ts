// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 12/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação das funções necessárias para conexão ao banco mongo
// ----------------------------------------------------------------------------- 

import {MongoClient} from "mongodb";
import type {Db, ClientSession} from "mongodb";
import {getEnv} from "./environment";

// Uma única conexão por processo, reutilizada entre invocações quentes.
let clientPromise: Promise<MongoClient> | undefined;

function getClient(): Promise<MongoClient> {
    if (!clientPromise) {
        const {mongodbUri} = getEnv();
        const client = new MongoClient(mongodbUri);

        // Se a conexão falhar, limpa a promise para permitir nova tentativa.
        clientPromise = client.connect().catch((error) => {
            clientPromise = undefined;
            throw error;
        });
    }

    return clientPromise;
}

export async function getDatabase(): Promise<Db> {
    const client = await getClient();
    // O mesmo cliente pode acessar bancos diferentes; o nome é resolvido a
    // partir da configuração validada em environment.ts.
    return client.db(getEnv().mongodbDb);
}

export async function closeClient(): Promise<void> {
    // Limpa a referência antes do fechamento para que chamadas futuras possam
    // criar uma nova conexão, por exemplo após encerramento controlado.
    const pending = clientPromise;
    clientPromise = undefined;
    if (!pending) return;

    // Se a conexão nunca foi estabelecida, não há nada a fechar.
    const client = await pending.catch(() => undefined);
    await client?.close();
}

// Executa as operações em uma transação (com retentativa de erros transitórios).
// Cada operação do repository deve receber a 'session' recebida aqui.
export async function runInTransaction<T>(
    operation: (session: ClientSession) => Promise<T>
): Promise<T> {
    const client = await getClient();
    return client.withSession((session) =>
        session.withTransaction(() => operation(session))
    );
}
