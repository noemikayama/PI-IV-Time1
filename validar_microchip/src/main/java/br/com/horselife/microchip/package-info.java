/**
 * Servidor de validação de microchip do HorseLife.
 *
 * <p>Pacote raiz: contém apenas o {@code Main}, que lê a configuração, monta as
 * dependências e inicia o servidor. Nenhuma regra de negócio fica aqui.
 *
 * <p>Dependências permitidas entre pacotes:
 * <pre>
 *   servidor  -&gt; protocolo -&gt; dominio
 *   todos     -&gt; modelos, utilitarios
 *   modelos e utilitarios não dependem de nenhum outro pacote do projeto
 * </pre>
 * Separar as camadas assim permite testar a regra do microchip com JUnit puro,
 * sem subir servidor nenhum.
 */
package br.com.horselife.microchip;
