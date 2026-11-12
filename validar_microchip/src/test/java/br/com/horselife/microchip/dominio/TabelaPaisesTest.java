// testes da tabela de paises iso 3166-1 lida do csv
package br.com.horselife.microchip.dominio;

import static java.nio.charset.StandardCharsets.ISO_8859_1;
import static java.nio.charset.StandardCharsets.UTF_8;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.ByteArrayInputStream;
import java.util.Optional;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class TabelaPaisesTest {

    private static TabelaPaises tabelaDe(String conteudo) {
        return TabelaPaises.ler(new ByteArrayInputStream(conteudo.getBytes(UTF_8)));
    }

    @Test
    void deveCarregar249Codigos() {
        TabelaPaises tabela = TabelaPaises.carregar();

        Set<String> codigos = tabela.codigos();

        assertEquals(249, codigos.size());
    }

    @Test
    void deveConterBrasilNoCodigo076() {
        TabelaPaises tabela = TabelaPaises.carregar();

        Optional<String> nome = tabela.nome("076");

        assertEquals(Optional.of("Brasil"), nome);
    }

    @ParameterizedTest
    @ValueSource(strings = {"000", "001", "419", "900", "999"})
    void naoDeveConterCodigoQueNaoEPais(String codigo) {
        TabelaPaises tabela = TabelaPaises.carregar();

        Optional<String> nome = tabela.nome(codigo);

        assertEquals(Optional.empty(), nome);
    }

    @Test
    void todosOsCodigosDevemTerTresDigitos() {
        TabelaPaises tabela = TabelaPaises.carregar();

        Set<String> codigos = tabela.codigos();

        assertTrue(codigos.stream().allMatch(codigo -> codigo.matches("\\d{3}")), codigos::toString);
    }

    @Test
    void deveLerNomesAcentuadosEmUtf8() {
        TabelaPaises tabela = TabelaPaises.carregar();

        Optional<String> nome = tabela.nome("040");

        assertEquals(Optional.of("Áustria"), nome);
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "codigo;nome\n076;Brasil\n",
        "codigo;nome\r\n076;Brasil\r\n",
        "codigo;nome\n076;Brasil"
    })
    void deveLerTabelaControlada(String conteudo) {
        TabelaPaises tabela = tabelaDe(conteudo);

        assertEquals(Optional.of("Brasil"), tabela.nome("076"));
        assertEquals(Set.of("076"), tabela.codigos());
    }

    @Test
    void deveFalharQuandoArquivoNaoExiste() {
        IllegalStateException erro =
                assertThrows(IllegalStateException.class, () -> TabelaPaises.carregar("/nao-existe.csv"));

        assertTrue(erro.getMessage().contains("/nao-existe.csv"), erro::getMessage);
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "",
        "codigo;nome\n",
        "076;Brasil\n",
        "﻿codigo;nome\n076;Brasil\n",
        "codigo;nome\n76;Brasil\n",
        "codigo;nome\n07a;Brasil\n",
        "codigo;nome\n076,Brasil\n",
        "codigo;nome\n076;Brasil;BR\n",
        "codigo;nome\n076; \n",
        "codigo;nome\n076;Brasil\n076;Brasil\n",
        "codigo;nome\n076;Brasil\n\n"
    })
    void deveFalharComArquivoMalformado(String conteudo) {
        assertThrows(IllegalStateException.class, () -> tabelaDe(conteudo));
    }

    @Test
    void deveIndicarALinhaDoErro() {
        IllegalStateException erro = assertThrows(IllegalStateException.class,
                () -> tabelaDe("codigo;nome\n076;Brasil\n32;Argentina\n"));

        assertTrue(erro.getMessage().contains("linha 3"), erro::getMessage);
    }

    @Test
    void deveFalharQuandoArquivoNaoEstaEmUtf8() {
        byte[] latin1 = "codigo;nome\n040;Áustria\n".getBytes(ISO_8859_1);

        assertThrows(IllegalStateException.class, () -> TabelaPaises.ler(new ByteArrayInputStream(latin1)));
    }
}
