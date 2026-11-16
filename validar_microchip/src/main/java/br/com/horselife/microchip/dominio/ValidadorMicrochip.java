// valida o microchip na ordem da secao 4; os dvs adaptam a regra do cpf e nao seguem a iso 11784
package br.com.horselife.microchip.dominio;

import br.com.horselife.microchip.modelos.CodigoErro;
import br.com.horselife.microchip.modelos.ResultadoValidacao;
import br.com.horselife.microchip.modelos.Validador;
import java.util.Optional;

public final class ValidadorMicrochip implements Validador {

    private static final int TAMANHO_MICROCHIP = 15;
    private static final int TAMANHO_CODIGO_PAIS = 3;
    private static final int POSICAO_DV1 = TAMANHO_MICROCHIP - 2;
    private static final int POSICAO_DV2 = TAMANHO_MICROCHIP - 1;
    private static final int MODULO = 11;

    private final TabelaPaises tabelaPaises;

    public ValidadorMicrochip(TabelaPaises tabelaPaises) {
        this.tabelaPaises = tabelaPaises;
    }

    @Override
    public ResultadoValidacao validar(String microchip) {
        if (microchip == null || microchip.isEmpty()) {
            return ResultadoValidacao.invalido(CodigoErro.MICROCHIP_AUSENTE);
        }
        if (!somenteDigitosAscii(microchip)) {
            return ResultadoValidacao.invalido(CodigoErro.FORMATO_INVALIDO);
        }
        if (microchip.length() != TAMANHO_MICROCHIP) {
            return ResultadoValidacao.invalido(CodigoErro.TAMANHO_INVALIDO);
        }
        if (todosIguais(microchip)) {
            return ResultadoValidacao.invalido(CodigoErro.SEQUENCIA_REPETIDA);
        }
        String codigoPais = microchip.substring(0, TAMANHO_CODIGO_PAIS);
        Optional<String> nomePais = tabelaPaises.nome(codigoPais);
        if (nomePais.isEmpty()) {
            return ResultadoValidacao.invalido(CodigoErro.PAIS_INVALIDO);
        }
        if (!digitoConfere(microchip, POSICAO_DV1) || !digitoConfere(microchip, POSICAO_DV2)) {
            return ResultadoValidacao.invalido(CodigoErro.DIGITO_VERIFICADOR_INVALIDO);
        }
        return ResultadoValidacao.valido(codigoPais, nomePais.get());
    }

    private static boolean somenteDigitosAscii(String texto) {
        return texto.chars().allMatch(c -> c >= '0' && c <= '9');
    }

    private static boolean todosIguais(String texto) {
        return texto.chars().allMatch(c -> c == texto.charAt(0));
    }

    private static boolean digitoConfere(String microchip, int posicao) {
        return calcularDigito(microchip.substring(0, posicao)) == microchip.charAt(posicao) - '0';
    }

    static int calcularDigito(String base) {
        int soma = 0;
        int peso = base.length() + 1;
        for (int i = 0; i < base.length(); i++) {
            soma += (base.charAt(i) - '0') * peso;
            peso--;
        }
        int resto = soma % MODULO;
        return resto < 2 ? 0 : MODULO - resto;
    }
}
