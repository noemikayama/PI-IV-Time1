// testes da leitura de uma linha utf-8 com limite de caracteres
package br.com.horselife.microchip.utilitarios;

import static java.nio.charset.StandardCharsets.UTF_8;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import br.com.horselife.microchip.utilitarios.LeitorLinhaLimitada.Leitura;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import org.junit.jupiter.api.Test;

class LeitorLinhaLimitadaTest {

    private static final int LIMITE = 1024;

    private static Reader leitor(String conteudo) {
        return new InputStreamReader(new ByteArrayInputStream(conteudo.getBytes(UTF_8)), UTF_8);
    }

    @Test
    void deveLerLinhaTerminadaEmQuebra() throws IOException {
        Reader entrada = leitor("{\"a\":1}\n");

        Leitura leitura = LeitorLinhaLimitada.lerLinha(entrada, LIMITE);

        assertEquals(new Leitura("{\"a\":1}", false), leitura);
    }

    @Test
    void deveLerSomenteAPrimeiraLinha() throws IOException {
        Reader entrada = leitor("a\nb\n");

        Leitura leitura = LeitorLinhaLimitada.lerLinha(entrada, LIMITE);

        assertEquals(new Leitura("a", false), leitura);
    }

    @Test
    void deveLerAcentosEmUtf8() throws IOException {
        Reader entrada = leitor("São João — coração\n");

        Leitura leitura = LeitorLinhaLimitada.lerLinha(entrada, LIMITE);

        assertEquals(new Leitura("São João — coração", false), leitura);
    }

    @Test
    void deveRemoverRetornoDeCarroFinal() throws IOException {
        Reader entrada = leitor("abc\r\n");

        Leitura leitura = LeitorLinhaLimitada.lerLinha(entrada, LIMITE);

        assertEquals(new Leitura("abc", false), leitura);
    }

    @Test
    void deveAceitarLinhaComExatamenteOLimite() throws IOException {
        Reader entrada = leitor("x".repeat(LIMITE) + "\n");

        Leitura leitura = LeitorLinhaLimitada.lerLinha(entrada, LIMITE);

        assertEquals(new Leitura("x".repeat(LIMITE), false), leitura);
    }

    @Test
    void deveAceitarLinhaComExatamenteOLimiteTerminadaEmRetornoDeCarro() throws IOException {
        Reader entrada = leitor("x".repeat(LIMITE) + "\r\n");

        Leitura leitura = LeitorLinhaLimitada.lerLinha(entrada, LIMITE);

        assertEquals(new Leitura("x".repeat(LIMITE), false), leitura);
    }

    @Test
    void deveSinalizarExcessoAcimaDoLimite() throws IOException {
        Reader entrada = leitor("x".repeat(LIMITE + 1) + "\n");

        Leitura leitura = LeitorLinhaLimitada.lerLinha(entrada, LIMITE);

        assertEquals(new Leitura(null, true), leitura);
    }

    @Test
    void deveSinalizarExcessoSemQuebraDeLinha() throws IOException {
        Reader entrada = leitor("x".repeat(5000));

        Leitura leitura = LeitorLinhaLimitada.lerLinha(entrada, LIMITE);

        assertEquals(new Leitura(null, true), leitura);
    }

    @Test
    void deveTratarFimDeStreamSemQuebra() throws IOException {
        Reader entrada = leitor("abc");

        Leitura leitura = LeitorLinhaLimitada.lerLinha(entrada, LIMITE);

        assertEquals(new Leitura("abc", false), leitura);
    }

    @Test
    void deveRetornarVazioQuandoStreamVazio() throws IOException {
        Reader entrada = leitor("");

        Leitura leitura = LeitorLinhaLimitada.lerLinha(entrada, LIMITE);

        assertEquals(new Leitura("", false), leitura);
    }

    @Test
    void deveRejeitarLimiteNaoPositivo() {
        Reader entrada = leitor("a");

        assertThrows(IllegalArgumentException.class, () -> LeitorLinhaLimitada.lerLinha(entrada, 0));
    }
}
