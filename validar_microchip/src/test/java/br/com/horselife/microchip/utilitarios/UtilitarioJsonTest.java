// testes da leitura e escrita de json do protocolo
package br.com.horselife.microchip.utilitarios;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;

import br.com.horselife.microchip.modelos.CodigoErro;
import br.com.horselife.microchip.modelos.Requisicao;
import br.com.horselife.microchip.modelos.Resposta;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import tools.jackson.core.JacksonException;

class UtilitarioJsonTest {

    @Test
    void deveSerializarRespostaValidaNaOrdemDoProtocolo() {
        Resposta resposta = Resposta.valida("076987654321017", "076", "Brasil");

        String json = UtilitarioJson.escrever(resposta);

        assertEquals("{\"valido\":true,\"microchip\":\"076987654321017\",\"codigoPais\":\"076\",\"nomePais\":\"Brasil\"}", json);
    }

    @Test
    void deveSerializarRespostaInvalidaComErroAninhado() {
        Resposta resposta = Resposta.invalida("076987654321018", CodigoErro.DIGITO_VERIFICADOR_INVALIDO);

        String json = UtilitarioJson.escrever(resposta);

        assertEquals("{\"valido\":false,\"microchip\":\"076987654321018\",\"erro\":{\"codigo\":\"DIGITO_VERIFICADOR_INVALIDO\",\"mensagem\":\"Os dígitos verificadores não conferem.\"}}", json);
    }

    @Test
    void deveOmitirMicrochipNoErroDeProtocolo() {
        Resposta resposta = Resposta.erroProtocolo(CodigoErro.REQUISICAO_MALFORMADA);

        String json = UtilitarioJson.escrever(resposta);

        assertEquals("{\"valido\":false,\"erro\":{\"codigo\":\"REQUISICAO_MALFORMADA\",\"mensagem\":\"A requisição não é um JSON válido.\"}}", json);
    }

    @Test
    void deveEscreverEmUmaUnicaLinhaMesmoComQuebraNoValor() {
        Resposta resposta = Resposta.valida("a\nb", "076", "Brasil");

        String json = UtilitarioJson.escrever(resposta);

        assertFalse(json.contains("\n"));
    }

    @Test
    void deveLerRequisicaoIgnorandoCamposExtras() {
        String json = "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":\"076987654321017\",\"extra\":1}";

        Requisicao requisicao = UtilitarioJson.ler(json, Requisicao.class);

        assertEquals(new Requisicao("VALIDAR_MICROCHIP", "076987654321017"), requisicao);
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":76987654321017}",
        "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":7.6}",
        "{\"comando\":true,\"microchip\":\"076987654321017\"}",
        "{\"comando\":\"VALIDAR_MICROCHIP\"} lixo"
    })
    void deveRecusarTiposNaoTextuaisELixoAposOJson(String json) {
        assertThrows(JacksonException.class, () -> UtilitarioJson.ler(json, Requisicao.class));
    }
}
