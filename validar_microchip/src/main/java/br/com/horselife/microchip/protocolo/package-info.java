/**
 * traducao entre json e chamadas ao dominio.
 *
 * <p>recebe a linha json como {@code string} e devolve um {@code resultado} com o
 * comando reconhecido, a resposta json e o desfecho que o servidor registra no log.
 * nao usa sockets, por isso e testavel sem rede.
 */
package br.com.horselife.microchip.protocolo;
