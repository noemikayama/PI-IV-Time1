// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 12/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Código temporário apenas para teste
// -----------------------------------------------------------------------------

import {getDatabase, closeClient} from "./shared/config/mongodb";

/** Confirma que a conexão com o MongoDB está disponível. */
async function main() {
  try {
    const db = await getDatabase();
    const res = await db.command({ping: 1});
    console.log("Resultado:", res);
  } finally {
    await closeClient();
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
