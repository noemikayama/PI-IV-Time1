// resultado da validacao: o pais quando valido, o codigo de erro quando invalido
package br.com.horselife.microchip.modelos;

public record ResultadoValidacao(boolean valido, CodigoErro codigoErro, String codigoPais, String nomePais) {

    public static ResultadoValidacao valido(String codigoPais, String nomePais) {
        return new ResultadoValidacao(true, null, codigoPais, nomePais);
    }

    public static ResultadoValidacao invalido(CodigoErro codigoErro) {
        return new ResultadoValidacao(false, codigoErro, null, null);
    }
}
