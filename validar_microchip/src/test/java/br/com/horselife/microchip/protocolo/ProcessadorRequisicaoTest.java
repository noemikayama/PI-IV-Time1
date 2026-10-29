// testes da traducao de uma linha json em resposta, com validador falso
package br.com.horselife.microchip.protocolo;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;

import br.com.horselife.microchip.modelos.CodigoErro;
import br.com.horselife.microchip.modelos.ResultadoValidacao;
import br.com.horselife.microchip.modelos.Validador;
import br.com.horselife.microchip.protocolo.ProcessadorRequisicao.Resultado;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;

class ProcessadorRequisicaoTest {

    private static final Validador VALIDO = m -> ResultadoValidacao.valido("076", "Brasil");

    @Test
    void deveResponderValidoConferindoCadaCampo() {
        ProcessadorRequisicao processador = new ProcessadorRequisicao(VALIDO);

        Resultado resultado = processador.processar(
                "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":\"076987654321017\"}");

        assertEquals(
                "{\"valido\":true,\"microchip\":\"076987654321017\",\"codigoPais\":\"076\",\"nomePais\":\"Brasil\"}",
                resultado.respostaJson());
        assertEquals("VALIDAR_MICROCHIP", resultado.comando());
        assertEquals("VALIDO", resultado.desfecho());
    }

    @Test
    void deveResponderInvalidoComCodigoEMensagem() {
        ProcessadorRequisicao processador = new ProcessadorRequisicao(
                m -> ResultadoValidacao.invalido(CodigoErro.DIGITO_VERIFICADOR_INVALIDO));

        Resultado resultado = processador.processar(
                "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":\"076987654321018\"}");

        assertEquals(
                "{\"valido\":false,\"microchip\":\"076987654321018\",\"erro\":{\"codigo\":\"DIGITO_VERIFICADOR_INVALIDO\",\"mensagem\":\"Os dígitos verificadores não conferem.\"}}",
                resultado.respostaJson());
        assertEquals("VALIDAR_MICROCHIP", resultado.comando());
        assertEquals("DIGITO_VERIFICADOR_INVALIDO", resultado.desfecho());
    }

    @ParameterizedTest
    @NullSource
    @ValueSource(strings = {
        "",
        "   ",
        "{",
        "não eh json",
        "null",
        "[]",
        "{\"microchip\":\"076987654321017\"}",
        "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":76987654321017}"
    })
    void deveRejeitarRequisicaoMalformada(String linha) {
        ProcessadorRequisicao processador = new ProcessadorRequisicao(VALIDO);

        Resultado resultado = processador.processar(linha);

        assertEquals(
                "{\"valido\":false,\"erro\":{\"codigo\":\"REQUISICAO_MALFORMADA\",\"mensagem\":\"A requisição não é um JSON válido.\"}}",
                resultado.respostaJson());
        assertNull(resultado.comando());
        assertEquals("REQUISICAO_MALFORMADA", resultado.desfecho());
    }

    @ParameterizedTest
    @ValueSource(strings = {"VALIDAR", "validar_microchip"})
    void deveRejeitarComandoDesconhecido(String comando) {
        ProcessadorRequisicao processador = new ProcessadorRequisicao(VALIDO);

        Resultado resultado = processador.processar(
                "{\"comando\":\"" + comando + "\",\"microchip\":\"076987654321017\"}");

        assertEquals(
                "{\"valido\":false,\"erro\":{\"codigo\":\"COMANDO_DESCONHECIDO\",\"mensagem\":\"O comando informado não é suportado.\"}}",
                resultado.respostaJson());
        assertNull(resultado.comando());
        assertEquals("COMANDO_DESCONHECIDO", resultado.desfecho());
    }

    @Test
    void deveRepassarMicrochipAusenteAoValidador() {
        AtomicReference<String> recebido = new AtomicReference<>("nao-chamado");
        ProcessadorRequisicao processador = new ProcessadorRequisicao(m -> {
            recebido.set(m);
            return ResultadoValidacao.invalido(CodigoErro.MICROCHIP_AUSENTE);
        });

        Resultado resultado = processador.processar("{\"comando\":\"VALIDAR_MICROCHIP\"}");

        assertNull(recebido.get());
        assertEquals(
                "{\"valido\":false,\"erro\":{\"codigo\":\"MICROCHIP_AUSENTE\",\"mensagem\":\"O microchip é obrigatório.\"}}",
                resultado.respostaJson());
        assertEquals("VALIDAR_MICROCHIP", resultado.comando());
        assertEquals("MICROCHIP_AUSENTE", resultado.desfecho());
    }

    @Test
    void deveResponderErroInternoSemVazarDetalhes() {
        ProcessadorRequisicao processador = new ProcessadorRequisicao(m -> {
            throw new IllegalStateException("segredo-interno");
        });

        Resultado resultado = processador.processar(
                "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":\"076987654321017\"}");

        assertEquals(
                "{\"valido\":false,\"erro\":{\"codigo\":\"ERRO_INTERNO\",\"mensagem\":\"Erro interno no servidor.\"}}",
                resultado.respostaJson());
        assertFalse(resultado.respostaJson().contains("segredo"));
        assertFalse(resultado.respostaJson().contains("Exception"));
        assertEquals("ERRO_INTERNO", resultado.desfecho());
    }

    @Test
    void deveMontarErroDeRequisicaoMuitoGrande() {
        ProcessadorRequisicao processador = new ProcessadorRequisicao(VALIDO);

        Resultado resultado = processador.erro(CodigoErro.REQUISICAO_MUITO_GRANDE);

        assertEquals(
                "{\"valido\":false,\"erro\":{\"codigo\":\"REQUISICAO_MUITO_GRANDE\",\"mensagem\":\"A requisição excede o limite de 1024 caracteres.\"}}",
                resultado.respostaJson());
        assertNull(resultado.comando());
        assertEquals("REQUISICAO_MUITO_GRANDE", resultado.desfecho());
    }
}
