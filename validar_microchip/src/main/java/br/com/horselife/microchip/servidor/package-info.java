/**
 * Sockets, threads e ciclo de vida da conexão.
 *
 * <p>Único pacote que usa {@link java.net.ServerSocket} e {@link java.net.Socket}.
 * Não conhece as regras de validação: só lê uma linha, delega ao protocolo e
 * escreve uma linha de resposta.
 */
package br.com.horselife.microchip.servidor;
