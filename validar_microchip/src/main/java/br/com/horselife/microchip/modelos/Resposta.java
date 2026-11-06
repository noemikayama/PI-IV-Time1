// resposta ao cliente; a ordem dos campos define a ordem no json e os nulos sao omitidos
package br.com.horselife.microchip.modelos;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record Resposta(boolean valido, String microchip, String codigoPais, String nomePais, Erro erro) {

    public static Resposta valida(String microchip, String codigoPais, String nomePais) {
        return new Resposta(true, microchip, codigoPais, nomePais, null);
    }

    public static Resposta invalida(String microchip, CodigoErro codigo) {
        return new Resposta(false, microchip, null, null, Erro.de(codigo));
    }

    public static Resposta erroProtocolo(CodigoErro codigo) {
        return new Resposta(false, null, null, null, Erro.de(codigo));
    }
}
