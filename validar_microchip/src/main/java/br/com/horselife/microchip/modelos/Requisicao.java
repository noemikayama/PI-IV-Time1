// requisicao recebida do cliente e o limite da sua linha; campo ausente no json chega como null
package br.com.horselife.microchip.modelos;

public record Requisicao(String comando, String microchip) {

    public static final int LIMITE_CARACTERES = 1024;
}
