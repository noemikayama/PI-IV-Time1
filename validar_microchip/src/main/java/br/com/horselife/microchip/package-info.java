/**
 * servidor de validacao de microchip do horselife.
 *
 * <p>pacote raiz: contem apenas o {@code main}, que le a configuracao, monta as
 * dependencias e inicia o servidor. nenhuma regra de negocio fica aqui.
 *
 * <p>dependencias permitidas entre pacotes:
 * <pre>
 *   servidor  -&gt; protocolo -&gt; dominio
 *   todos     -&gt; modelos, utilitarios
 *   modelos e utilitarios nao dependem de nenhum outro pacote do projeto
 * </pre>
 * separar as camadas assim permite testar a regra do microchip com junit puro,
 * sem subir servidor nenhum.
 */
package br.com.horselife.microchip;
