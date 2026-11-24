// contrato da validacao; o protocolo depende dele e nao do dominio, para testar com um falso
package br.com.horselife.microchip.modelos;

@FunctionalInterface
public interface Validador {

    ResultadoValidacao validar(String microchip);
}
