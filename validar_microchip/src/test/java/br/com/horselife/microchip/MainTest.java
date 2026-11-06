// testes da leitura da porta configurada pela variavel microchip_porta
package br.com.horselife.microchip;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

class MainTest {

    @Test
    void deveUsarPortaPadraoQuandoVariavelAusente() {
        int porta = Main.resolverPorta(null);

        assertEquals(7700, porta);
    }

    @ParameterizedTest
    @CsvSource({"7800, 7800", "1, 1", "65535, 65535"})
    void deveUsarPortaDaVariavelQuandoValida(String valor, int esperada) {
        int porta = Main.resolverPorta(valor);

        assertEquals(esperada, porta);
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "abc", "0", "-1", "65536", " 7800", "+7800", "99999999999"})
    void deveRejeitarPortaInvalidaComMensagemClara(String valor) {
        IllegalArgumentException erro =
                assertThrows(IllegalArgumentException.class, () -> Main.resolverPorta(valor));

        assertTrue(erro.getMessage().contains("MICROCHIP_PORTA"), erro::getMessage);
        assertTrue(erro.getMessage().contains("'" + valor + "'"), erro::getMessage);
    }
}
