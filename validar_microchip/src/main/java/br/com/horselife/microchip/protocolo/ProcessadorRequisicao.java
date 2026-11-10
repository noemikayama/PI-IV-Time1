// traduz uma linha json em chamada ao validador e devolve a resposta em json, sem sockets
package br.com.horselife.microchip.protocolo;

import br.com.horselife.microchip.modelos.CodigoErro;
import br.com.horselife.microchip.modelos.Requisicao;
import br.com.horselife.microchip.modelos.Resposta;
import br.com.horselife.microchip.modelos.ResultadoValidacao;
import br.com.horselife.microchip.modelos.Validador;
import br.com.horselife.microchip.utilitarios.UtilitarioJson;
import java.util.logging.Level;
import java.util.logging.Logger;
import tools.jackson.core.JacksonException;

public final class ProcessadorRequisicao {

    private static final Logger LOGGER = Logger.getLogger(ProcessadorRequisicao.class.getName());
    private static final String VALIDAR_MICROCHIP = "VALIDAR_MICROCHIP";
    private static final String DESFECHO_VALIDO = "VALIDO";

    private final Validador validador;

    public ProcessadorRequisicao(Validador validador) {
        this.validador = validador;
    }

    public Resultado processar(String linha) {
        try {
            return interpretar(linha);
        } catch (RuntimeException e) {
            LOGGER.log(Level.SEVERE, "Falha inesperada ao processar a requisição.", e);
            return erro(CodigoErro.ERRO_INTERNO);
        }
    }

    private Resultado interpretar(String linha) {
        if (linha == null || linha.isBlank()) {
            return erro(CodigoErro.REQUISICAO_MALFORMADA);
        }
        Requisicao requisicao;
        try {
            requisicao = UtilitarioJson.ler(linha, Requisicao.class);
        } catch (JacksonException e) {
            return erro(CodigoErro.REQUISICAO_MALFORMADA);
        }
        if (requisicao == null || requisicao.comando() == null) {
            return erro(CodigoErro.REQUISICAO_MALFORMADA);
        }
        if (!VALIDAR_MICROCHIP.equals(requisicao.comando())) {
            return erro(CodigoErro.COMANDO_DESCONHECIDO);
        }
        String microchip = requisicao.microchip();
        try {
            ResultadoValidacao validacao = validador.validar(microchip);
            if (validacao.valido()) {
                Resposta resposta = Resposta.valida(microchip, validacao.codigoPais(), validacao.nomePais());
                return new Resultado(VALIDAR_MICROCHIP, UtilitarioJson.escrever(resposta), DESFECHO_VALIDO);
            }
            Resposta resposta = Resposta.invalida(microchip, validacao.codigoErro());
            return new Resultado(VALIDAR_MICROCHIP, UtilitarioJson.escrever(resposta), validacao.codigoErro().name());
        } catch (RuntimeException e) {
            LOGGER.log(Level.SEVERE, "Falha inesperada ao validar o microchip.", e);
            return erro(VALIDAR_MICROCHIP, CodigoErro.ERRO_INTERNO);
        }
    }

    public Resultado erro(CodigoErro codigo) {
        return erro(null, codigo);
    }

    private Resultado erro(String comando, CodigoErro codigo) {
        return new Resultado(comando, UtilitarioJson.escrever(Resposta.erroProtocolo(codigo)), codigo.name());
    }

    public record Resultado(String comando, String respostaJson, String desfecho) {
    }
}
