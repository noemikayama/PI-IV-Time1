// Projeto HorseLife — PI IV
// Arquivo: TesteOOIntraclasseTest.java
// Objetivo: testar isoladamente comportamentos de duas classes do domínio.
// Técnicas de Teste OO: categorias de métodos (ValidadorMicrochip)
// e particionamento por atributos (TabelaPaises).
// Documentação dos testes: Gabriela Sichiroli Ferrari — 20/11/2026.
package br.com.horselife.microchip.dominio;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import br.com.horselife.microchip.modelos.CodigoErro;
import br.com.horselife.microchip.modelos.ResultadoValidacao;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.util.Optional;
import org.junit.jupiter.api.Test;

/**
 * Reúne seis testes intraclasse automatizados com JUnit 5.
 *
 * Os testes seguem o padrão AAA:
 * Arrange (preparar os objetos), Act (executar o método)
 * e Assert (comparar o resultado obtido com o esperado).
 *
 * Classes e critérios avaliados:
 * - ValidadorMicrochip: categorias de métodos validar e calcularDigito.
 * - TabelaPaises: atributo paises, com chave presente, ausente ou duplicada.
 */
class TesteOOIntraclasseTest {

    /**
     * CT-01 — ValidadorMicrochip / categoria VALIDAR.
     * Partição: microchip válido; espera identificação do Brasil.
     */
    // A anotação @Test registra este método como um caso de teste JUnit.
    @Test
    void validador_deveAceitarMicrochipValido() {
        // Arrange: carrega os países e cria a instância real do validador.
        ValidadorMicrochip validador = new ValidadorMicrochip(TabelaPaises.carregar());

        // Act: submete um identificador cujos dígitos verificadores são válidos.
        ResultadoValidacao resultado = validador.validar("076987654321017");

        // Assert: o retorno deve indicar validação positiva e país Brasil (076).
        assertEquals(ResultadoValidacao.valido("076", "Brasil"), resultado);
    }

    /**
     * CT-02 — ValidadorMicrochip / categoria VALIDAR.
     * Partição: microchip com dígito verificador incorreto.
     */
    @Test
    void validador_deveRecusarDigitoVerificadorIncorreto() {
        // Arrange: disponibiliza a tabela de países ao validador.
        ValidadorMicrochip validador = new ValidadorMicrochip(TabelaPaises.carregar());

        // Act: altera o dígito final em relação ao identificador válido.
        ResultadoValidacao resultado = validador.validar("076987654321018");

        // Assert: espera o erro de negócio específico, não uma validação positiva.
        assertEquals(ResultadoValidacao.invalido(CodigoErro.DIGITO_VERIFICADOR_INVALIDO), resultado);
    }

    /**
     * CT-03 — ValidadorMicrochip / categoria CÁLCULO.
     * Verifica diretamente o método de cálculo do dígito verificador.
     */
    @Test
    void validador_deveCalcularDigitoVerificador() {
        // Act + Assert: calcula o dígito para a sequência fornecida e espera 1.
        // O método possui acesso de pacote; o teste está no mesmo pacote de domínio.
        assertEquals(1, ValidadorMicrochip.calcularDigito("0769876543210"));
    }

    /**
     * CT-04 — TabelaPaises / particionamento por ATRIBUTOS.
     * Estado do atributo paises: chave "076" existente.
     */
    @Test
    void tabela_deveEncontrarCodigoExistente() {
        // Arrange: carrega o mapa de códigos e nomes dos países.
        TabelaPaises tabela = TabelaPaises.carregar();

        // Act + Assert: consulta "076" e espera um Optional contendo "Brasil".
        assertEquals(Optional.of("Brasil"), tabela.nome("076"));
    }

    /**
     * CT-05 — TabelaPaises / particionamento por ATRIBUTOS.
     * Estado do atributo paises: chave "999" ausente.
     */
    @Test
    void tabela_deveRetornarVazioParaCodigoInexistente() {
        // Arrange: carrega a tabela com os códigos disponíveis.
        TabelaPaises tabela = TabelaPaises.carregar();

        // Act + Assert: uma chave não cadastrada deve retornar Optional.empty().
        assertEquals(Optional.empty(), tabela.nome("999"));
    }

    /**
     * CT-06 — TabelaPaises / particionamento por ATRIBUTOS.
     * Condição inválida de carga: duas linhas com a mesma chave "076".
     */
    @Test
    void tabela_deveRejeitarCsvComCodigoDuplicado() {
        // Arrange: cria um CSV fictício com cabeçalho e código duplicado.
        String csv = "codigo;nome\n076;Brasil\n076;Brasil duplicado\n";

        // Simula a leitura de um arquivo usando dados em memória (sem arquivo físico).
        ByteArrayInputStream entrada = new ByteArrayInputStream(csv.getBytes(StandardCharsets.UTF_8));

        // Act + Assert: duplicidade deve gerar IllegalStateException.
        // assertThrows aprova o teste quando a exceção esperada é lançada.
        assertThrows(IllegalStateException.class, () -> TabelaPaises.ler(entrada));
    }
}
