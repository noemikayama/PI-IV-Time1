// testes das regras de validacao do microchip e do calculo dos digitos verificadores
package br.com.horselife.microchip.dominio;

import static java.nio.charset.StandardCharsets.UTF_8;
import static org.junit.jupiter.api.Assertions.assertEquals;

import br.com.horselife.microchip.modelos.CodigoErro;
import br.com.horselife.microchip.modelos.ResultadoValidacao;
import java.io.ByteArrayInputStream;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

class ValidadorMicrochipTest {

    private final ValidadorMicrochip validador = new ValidadorMicrochip(TabelaPaises.carregar());

    private static String comDigitosCorretos(String base13) {
        String comDv1 = base13 + ValidadorMicrochip.calcularDigito(base13);
        return comDv1 + ValidadorMicrochip.calcularDigito(comDv1);
    }

    @ParameterizedTest
    @ValueSource(strings = {"076987654321017", "076123456789008"})
    void deveAceitarExemplosValidosDaEspecificacao(String microchip) {
        ResultadoValidacao resultado = validador.validar(microchip);

        assertEquals(ResultadoValidacao.valido("076", "Brasil"), resultado);
    }

    @Test
    void deveManterZeroAEsquerdaDoCodigoDoPais() {
        ResultadoValidacao resultado = validador.validar("076987654321017");

        assertEquals("076", resultado.codigoPais());
    }

    @ParameterizedTest
    @NullAndEmptySource
    void deveRejeitarMicrochipAusente(String microchip) {
        ResultadoValidacao resultado = validador.validar(microchip);

        assertEquals(ResultadoValidacao.invalido(CodigoErro.MICROCHIP_AUSENTE), resultado);
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "076.987.654.321-01",
        "   ",
        "076987654321017 ",
        "+76987654321017",
        "０７６９８７６５４３２１０１７"
    })
    void deveRejeitarFormatoInvalido(String microchip) {
        ResultadoValidacao resultado = validador.validar(microchip);

        assertEquals(ResultadoValidacao.invalido(CodigoErro.FORMATO_INVALIDO), resultado);
    }

    @ParameterizedTest
    @ValueSource(strings = {"07698765432101", "0769876543210170", "1111111111111111"})
    void deveRejeitarTamanhoInvalido(String microchip) {
        ResultadoValidacao resultado = validador.validar(microchip);

        assertEquals(ResultadoValidacao.invalido(CodigoErro.TAMANHO_INVALIDO), resultado);
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "000000000000000", "111111111111111", "222222222222222", "333333333333333", "444444444444444",
        "555555555555555", "666666666666666", "777777777777777", "888888888888888", "999999999999999"
    })
    void deveRejeitarSequenciaRepetida(String microchip) {
        ResultadoValidacao resultado = validador.validar(microchip);

        assertEquals(ResultadoValidacao.invalido(CodigoErro.SEQUENCIA_REPETIDA), resultado);
    }

    @ParameterizedTest
    @ValueSource(strings = {"9991234567890", "9001234567890", "0011234567890"})
    void deveRejeitarPaisInvalidoMesmoComDigitosCorretos(String base13) {
        String microchip = comDigitosCorretos(base13);

        ResultadoValidacao resultado = validador.validar(microchip);

        assertEquals(ResultadoValidacao.invalido(CodigoErro.PAIS_INVALIDO), resultado);
    }

    @Test
    void deveVerificarPaisAntesDosDigitosVerificadores() {
        ResultadoValidacao resultado = validador.validar("999123456789000");

        assertEquals(ResultadoValidacao.invalido(CodigoErro.PAIS_INVALIDO), resultado);
    }

    @ParameterizedTest
    @ValueSource(strings = {"076987654321027", "076987654321018", "076987654321025"})
    void deveRejeitarDigitoVerificadorIncorreto(String microchip) {
        ResultadoValidacao resultado = validador.validar(microchip);

        assertEquals(ResultadoValidacao.invalido(CodigoErro.DIGITO_VERIFICADOR_INVALIDO), resultado);
    }

    @ParameterizedTest
    @CsvSource({
        "0761234567890, 0",
        "0760000000007, 0",
        "0760000000002, 9",
        "0769876543210, 1",
        "07698765432101, 7",
        "07612345678900, 8"
    })
    void deveCalcularDigitoVerificador(String base, int esperado) {
        int digito = ValidadorMicrochip.calcularDigito(base);

        assertEquals(esperado, digito);
    }

    @Test
    void deveConsultarATabelaRecebidaNoConstrutor() {
        TabelaPaises somenteArgentina = TabelaPaises.ler(
                new ByteArrayInputStream("codigo;nome\n032;Argentina\n".getBytes(UTF_8)));
        ValidadorMicrochip validadorComTabelaControlada = new ValidadorMicrochip(somenteArgentina);

        ResultadoValidacao resultado = validadorComTabelaControlada.validar("076987654321017");

        assertEquals(ResultadoValidacao.invalido(CodigoErro.PAIS_INVALIDO), resultado);
    }
}
