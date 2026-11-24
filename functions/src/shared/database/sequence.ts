// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Reserva de um bloco de códigos em uma única operação, usada
// na geração dos registros de treino do plano.
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

/** Gera o próximo código sequencial para a coleção indicada. Com 'count'
 * maior que 1, reserva um bloco: os códigos vão de (retorno - count + 1)
 * até o retorno, em uma única ida ao banco.
 * @param {string} sequenceName Nome do contador.
 * @param {ClientSession} session Sessão da transação.
 * @param {number} count Quantidade de códigos reservados.
 * @return {Promise<number>} Último código reservado.
 */
export async function nextCode(
  sequenceName: string,
  session: ClientSession,
  count = 1
): Promise<number> {
  const db = await getDatabase();

  const counter = await db
    .collection<Counter>(COLLECTIONS.Contadores)
    .findOneAndUpdate(
      {_id: sequenceName},
      {$inc: {seq: count}},
      {upsert: true, returnDocument: "after", session}
    );

  if (!counter) throw new Error("Falha ao gerar o código sequencial.");
  return counter.seq;
}
