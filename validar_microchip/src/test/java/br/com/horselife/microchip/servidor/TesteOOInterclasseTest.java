// Projeto HorseLife — PI IV
// Objetivo: verificar a integração real entre TCP, protocolo JSON e domínio.
// Cenários: operação normal e rejeição por dígito verificador inválido.
// Documentação dos testes: Gabriela Sichiroli Ferrari — 20/11/2026.
package br.com.horselife.microchip.servidor;

import static org.junit.jupiter.api.Assertions.assertEquals;

import br.com.horselife.microchip.dominio.TabelaPaises;
import br.com.horselife.microchip.dominio.ValidadorMicrochip;
import br.com.horselife.microchip.protocolo.ProcessadorRequisicao;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;

/**
 * Testes interclasse do serviço VALIDAR_MICROCHIP com JUnit 5.
 *
 * O teste inicia um servidor real, conecta um cliente por TCP local,
 * envia uma requisição JSON e compara a resposta JSON recebida.
 * Não são usados mocks para substituir o ValidadorMicrochip.
 *
 * Fluxo exercitado (alto nível): cliente TCP -> ServidorMicrochip ->
 * TratadorConexao -> ProcessadorRequisicao -> ValidadorMicrochip ->
 * TabelaPaises -> resposta JSON -> cliente TCP.
 */
// Limita cada teste a 10 segundos, evitando execução indefinida.
@Timeout(10)
class TesteOOInterclasseTest {

    /**
     * Método auxiliar compartilhado pelos dois cenários.
     *
     * @param microchip identificador a ser enviado na requisição JSON
     * @return uma linha JSON devolvida pelo servidor
     * @throws IOException se houver problema de entrada/saída na conexão TCP
     */
    private String consultarServidor(String microchip) throws IOException {
        // Arrange: monta o processador com os objetos REAIS do domínio.
        // Carrega a tabela de países, cria o validador e injeta-o no processador.
        ProcessadorRequisicao processador = new ProcessadorRequisicao(
                new ValidadorMicrochip(TabelaPaises.carregar()));

        // Porta 0: o sistema operacional escolhe uma porta TCP disponível.
        // Duration.ofSeconds(5): configuração de tempo de leitura do servidor.
        // try-with-resources fecha o servidor automaticamente ao fim do bloco.
        try (ServidorMicrochip servidor = new ServidorMicrochip(0, Duration.ofSeconds(5), processador)) {
            // Inicializa a escuta do servidor antes de o cliente se conectar.
            servidor.iniciar();

            // Abre uma conexão TCP no endereço local (loopback) e porta escolhida.
            // O socket do cliente também será fechado automaticamente.
            try (Socket cliente = new Socket(InetAddress.getLoopbackAddress(), servidor.portaLocal())) {
                // Escritor: envia texto ao servidor, codificado em UTF-8.
                BufferedWriter escritor = new BufferedWriter(new OutputStreamWriter(
                        cliente.getOutputStream(), StandardCharsets.UTF_8));

                // Leitor: recebe do servidor a resposta textual em UTF-8.
                BufferedReader leitor = new BufferedReader(new InputStreamReader(
                        cliente.getInputStream(), StandardCharsets.UTF_8));

                // Act: envia o comando principal e o microchip no formato JSON.
                // O \n encerra a linha, permitindo ao servidor identificar a mensagem completa.
                escritor.write("{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":\"" + microchip + "\"}\n");

                // Força a transmissão dos caracteres acumulados no buffer.
                escritor.flush();

                // Aguarda e retorna a linha JSON de resposta para a asserção do teste.
                return leitor.readLine();
            }
        }
    }

    /**
     * CT-07 — CENÁRIO NORMAL.
     * Objetivo: microchip válido deve produzir resposta positiva, com país Brasil.
     */
    @Test
    void normal_deveResponderMicrochipValido() throws IOException {
        // Act: percorre rede TCP, interpretação JSON e validação do domínio.
        String resposta = consultarServidor("076987654321017");

        // Assert: compara o JSON textual obtido com a resposta completa esperada.
        // A comparação também verifica campos e sua ordem na serialização atual.
        assertEquals("{\"valido\":true,\"microchip\":\"076987654321017\","
                + "\"codigoPais\":\"076\",\"nomePais\":\"Brasil\"}", resposta);
    }

    /**
     * CT-08 — CENÁRIO ALTERNATIVO / ERRO DE NEGÓCIO.
     * Objetivo: dígito incorreto deve gerar JSON de erro sem exceção ao cliente.
     */
    @Test
    void alternativo_deveRecusarDigitoVerificadorInvalido() throws IOException {
        // Act: envia um identificador com dígito verificador incorreto.
        String resposta = consultarServidor("076987654321018");

        // Assert: o serviço deve responder valido=false e código de erro definido.
        // Não esperamos um throw neste cenário: o erro é uma resposta de negócio.
        assertEquals("{\"valido\":false,\"microchip\":\"076987654321018\","
                + "\"erro\":{\"codigo\":\"DIGITO_VERIFICADOR_INVALIDO\","
                + "\"mensagem\":\"Os dígitos verificadores não conferem.\"}}", resposta);
    }
}