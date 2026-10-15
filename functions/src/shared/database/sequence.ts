// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Criação do gerador de códigos sequenciais por coleção.
// -----------------------------------------------------------------------------

// Gerador do campo 'codigo' (inteiro sequencial, um contador por coleção).
// Deve ser chamado dentro de uma transação: se ela for abortada, o contador
// volta ao valor anterior e nenhum código é perdido.
import type {ClientSession} from "mongodb";
import {getDatabase} from "../config/mongodb";
import {COLLECTIONS} from "../constants/collections";

type Counter = {_id: string; seq: number};

/** Gera o próximo código sequencial para a coleção indicada.
 * @param {string} sequenceName Nome do contador.
 * @param {ClientSession} session Sessão da transação.
 */
export async function nextCode(
  sequenceName: string,
  session: ClientSession
): Promise<number> {
  const db = await getDatabase();

  const counter = await db
    .collection<Counter>(COLLECTIONS.contadores)
    .findOneAndUpdate(
      {_id: sequenceName},
      {$inc: {seq: 1}},
      {upsert: true, returnDocument: "after", session}
    );

  if (!counter) throw new Error("Falha ao gerar o código sequencial.");
  return counter.seq;
}
