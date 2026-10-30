// testes de integracao do servidor tcp com sockets reais na porta 0
package br.com.horselife.microchip.servidor;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import br.com.horselife.microchip.modelos.CodigoErro;
import br.com.horselife.microchip.modelos.ResultadoValidacao;
import br.com.horselife.microchip.modelos.Validador;
import br.com.horselife.microchip.protocolo.ProcessadorRequisicao;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.BindException;
import java.net.ConnectException;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.RepeatedTest;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Timeout;

@Timeout(15)
class ServidorMicrochipIntegracaoTest {

    private static final String REQUISICAO =
            "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":\"076987654321017\"}";
    private static final String RESPOSTA_VALIDA =
            "{\"valido\":true,\"microchip\":\"076987654321017\",\"codigoPais\":\"076\",\"nomePais\":\"Brasil\"}";
    private static final Validador VALIDO = m -> ResultadoValidacao.valido("076", "Brasil");
    private static final Duration TIMEOUT_PADRAO = Duration.ofSeconds(5);

    private final List<ServidorMicrochip> servidores = new ArrayList<>();

    @AfterEach
    void encerrarServidores() {
        servidores.forEach(ServidorMicrochip::encerrar);
    }

    private ServidorMicrochip iniciarServidor(Validador validador, Duration timeoutLeitura) throws IOException {
        ServidorMicrochip servidor = criarServidor(0, validador, timeoutLeitura);
        servidor.iniciar();
        return servidor;
    }

    private ServidorMicrochip criarServidor(int porta, Validador validador, Duration timeoutLeitura) {
        ServidorMicrochip servidor = new ServidorMicrochip(porta, timeoutLeitura, new ProcessadorRequisicao(validador));
        servidores.add(servidor);
        return servidor;
    }

    private static String enviar(int porta, String linha) throws IOException {
        try (Socket socket = new Socket("localhost", porta)) {
            BufferedWriter escritor = new BufferedWriter(
                    new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8));
            BufferedReader leitor = new BufferedReader(
                    new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
            escritor.write(linha + "\n");
            escritor.flush();
            return leitor.readLine();
        }
    }

    @Test
    void deveResponderValidoNaIdaEVolta() throws IOException {
        ServidorMicrochip servidor = iniciarServidor(VALIDO, TIMEOUT_PADRAO);

        String resposta = enviar(servidor.portaLocal(), REQUISICAO);

        assertEquals(RESPOSTA_VALIDA, resposta);
    }

    @Test
    void deveTransmitirAcentosEmUtf8() throws IOException {
        ServidorMicrochip servidor = iniciarServidor(
                m -> ResultadoValidacao.invalido(CodigoErro.DIGITO_VERIFICADOR_INVALIDO), TIMEOUT_PADRAO);

        String resposta = enviar(servidor.portaLocal(),
                "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":\"076987654321018\"}");

        assertEquals(
                "{\"valido\":false,\"microchip\":\"076987654321018\",\"erro\":{\"codigo\":\"DIGITO_VERIFICADOR_INVALIDO\",\"mensagem\":\"Os dígitos verificadores não conferem.\"}}",
                resposta);
    }

    @Test
    void deveAtenderConexoesSimultaneas() throws Exception {
        int quantidade = 20;
        CountDownLatch todosChegaram = new CountDownLatch(quantidade);
        ServidorMicrochip servidor = iniciarServidor(m -> {
            todosChegaram.countDown();
            try {
                todosChegaram.await(5, TimeUnit.SECONDS);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            return ResultadoValidacao.valido("076", "Brasil");
        }, TIMEOUT_PADRAO);

        List<Future<String>> respostas = new ArrayList<>();
        try (ExecutorService clientes = Executors.newVirtualThreadPerTaskExecutor()) {
            for (int i = 0; i < quantidade; i++) {
                respostas.add(clientes.submit(() -> enviar(servidor.portaLocal(), REQUISICAO)));
            }
        }

        assertEquals(0, todosChegaram.getCount());
        for (Future<String> resposta : respostas) {
            assertEquals(RESPOSTA_VALIDA, resposta.get());
        }
    }

    @RepeatedTest(20)
    void deveResponderRequisicaoMuitoGrandeSemPerderResposta() throws IOException {
        ServidorMicrochip servidor = iniciarServidor(VALIDO, TIMEOUT_PADRAO);

        String resposta = enviar(servidor.portaLocal(), "x".repeat(200_000));

        assertEquals(
                "{\"valido\":false,\"erro\":{\"codigo\":\"REQUISICAO_MUITO_GRANDE\",\"mensagem\":\"A requisição excede o limite de 1024 caracteres.\"}}",
                resposta);
    }

    @Test
    void deveFecharConexaoOciosaAposTimeout() throws IOException {
        ServidorMicrochip servidor = iniciarServidor(VALIDO, Duration.ofMillis(200));

        long inicio = System.nanoTime();
        String respostaOciosa;
        try (Socket socket = new Socket("localhost", servidor.portaLocal())) {
            BufferedReader leitor = new BufferedReader(
                    new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
            respostaOciosa = leitor.readLine();
        }
        Duration decorrido = Duration.ofNanos(System.nanoTime() - inicio);
        String respostaSeguinte = enviar(servidor.portaLocal(), REQUISICAO);

        assertNull(respostaOciosa);
        assertTrue(decorrido.compareTo(Duration.ofSeconds(2)) < 0, "demorou " + decorrido);
        assertEquals(RESPOSTA_VALIDA, respostaSeguinte);
    }

    @Test
    void deveConcluirRequisicaoEmAndamentoAoEncerrar() throws Exception {
        CountDownLatch entrou = new CountDownLatch(1);
        CountDownLatch liberar = new CountDownLatch(1);
        ServidorMicrochip servidor = iniciarServidor(m -> {
            entrou.countDown();
            try {
                liberar.await(10, TimeUnit.SECONDS);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
            return ResultadoValidacao.valido("076", "Brasil");
        }, TIMEOUT_PADRAO);
        int porta = servidor.portaLocal();

        CompletableFuture<String> resposta = CompletableFuture.supplyAsync(() -> {
            try {
                return enviar(porta, REQUISICAO);
            } catch (IOException e) {
                throw new IllegalStateException(e);
            }
        });
        assertTrue(entrou.await(5, TimeUnit.SECONDS));
        CompletableFuture<Void> encerramento = CompletableFuture.runAsync(servidor::encerrar);
        liberar.countDown();
        encerramento.get(12, TimeUnit.SECONDS);

        assertEquals(RESPOSTA_VALIDA, resposta.get(5, TimeUnit.SECONDS));
        assertThrows(ConnectException.class, () -> new Socket("localhost", porta).close());
    }

    @Test
    void deveFalharAoIniciarEmPortaOcupada() throws IOException {
        ServidorMicrochip primeiro = iniciarServidor(VALIDO, TIMEOUT_PADRAO);
        ServidorMicrochip segundo = criarServidor(primeiro.portaLocal(), VALIDO, TIMEOUT_PADRAO);

        assertThrows(BindException.class, segundo::iniciar);
    }
}
