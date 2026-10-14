// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Código temporário apenas para teste
// ----------------------------------------------------------------------------- 

// Script de teste manual: confirma que o Admin SDK consegue acessar o projeto.
import {auth} from "./shared/config/firebase";

async function main() {
    const result = await auth.listUsers(1);
    console.log("Conexão OK. Usuários retornados:", result.users.length);
}

main().catch((err) => {
    console.error(err);
    process.exitCode = 1;
});
