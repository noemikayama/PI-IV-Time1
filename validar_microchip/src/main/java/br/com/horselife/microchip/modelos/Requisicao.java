// requisicao recebida do cliente; campo ausente no json chega como null
package br.com.horselife.microchip.modelos;

public record Requisicao(String comando, String microchip) {
}
