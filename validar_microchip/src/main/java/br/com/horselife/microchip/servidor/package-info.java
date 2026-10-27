/**
 * sockets, threads e ciclo de vida da conexao.
 *
 * <p>unico pacote que usa {@code serversocket} e {@code socket}.
 * nao conhece as regras de validacao: so le uma linha, delega ao protocolo e
 * escreve uma linha de resposta.
 */
package br.com.horselife.microchip.servidor;
