// erro aninhado na resposta: codigo e mensagem para o cliente
package br.com.horselife.microchip.modelos;

public record Erro(CodigoErro codigo, String mensagem) {

    public static Erro de(CodigoErro codigo) {
        return new Erro(codigo, codigo.mensagem());
    }
}
