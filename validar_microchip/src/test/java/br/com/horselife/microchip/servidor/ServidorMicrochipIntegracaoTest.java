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
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import java.util.logging.Handler;
import java.util.logging.LogRecord;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;
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

    private ServidorMicrochip criarServidor(ServidorMicrochip.FabricaServidorSocket fabricaSocket) {
        ServidorMicrochip servidor = new ServidorMicrochip(
                0, TIMEOUT_PADRAO, new ProcessadorRequisicao(VALIDO), fabricaSocket);
        servidores.add(servidor);
        return servidor;
    }

    private static void aguardar(CountDownLatch sinal) {
        try {
            if (!sinal.await(10, TimeUnit.SECONDS)) {
                throw new IllegalStateException("O sinal esperado pelo teste não chegou.");
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
    }

    private static void aguardarNoMaximo(Future<?> tarefa, Duration limite) throws Exception {
        try {
            tarefa.get(limite.toMillis(), TimeUnit.MILLISECONDS);
        } catch (TimeoutException e) {
            return;
        }
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
    void deveResponderConexaoAceitaLogoAntesDoEncerramento() throws Exception {
        CountDownLatch aceitou = new CountDownLatch(1);
        CountDownLatch liberarAceitador = new CountDownLatch(1);
        CountDownLatch fechou = new CountDownLatch(1);
        ServidorMicrochip servidor = criarServidor(porta -> new ServerSocket(porta) {
            @Override
            public Socket accept() throws IOException {
                Socket socket = super.accept();
                aceitou.countDown();
                aguardar(liberarAceitador);
                return socket;
            }

            @Override
            public void close() throws IOException {
                super.close();
                fechou.countDown();
            }
        });
        servidor.iniciar();
        int porta = servidor.portaLocal();

        CompletableFuture<String> resposta = CompletableFuture.supplyAsync(() -> {
            try {
                return enviar(porta, REQUISICAO);
            } catch (IOException e) {
                throw new IllegalStateException(e);
            }
        });
        aguardar(aceitou);
        CompletableFuture<Void> encerramento = CompletableFuture.runAsync(servidor::encerrar);
        aguardar(fechou);
        aguardarNoMaximo(encerramento, Duration.ofMillis(500));
        liberarAceitador.countDown();
        encerramento.get(12, TimeUnit.SECONDS);

        assertEquals(RESPOSTA_VALIDA, resposta.get(5, TimeUnit.SECONDS));
    }

    @Test
    void deveContinuarTentandoComPausaQuandoAceitarFalha() throws Exception {
        AtomicInteger tentativas = new AtomicInteger();
        ServidorMicrochip servidor = criarServidor(porta -> new ServerSocket(porta) {
            @Override
            public Socket accept() throws IOException {
                tentativas.incrementAndGet();
                throw new IOException("falha simulada ao aceitar conexão");
            }
        });
        Logger logger = Logger.getLogger(ServidorMicrochip.class.getName());
        logger.setUseParentHandlers(false);
        try {
            servidor.iniciar();
            Thread.sleep(500);
            servidor.encerrar();
        } finally {
            logger.setUseParentHandlers(true);
        }

        assertTrue(tentativas.get() >= 2, "tentativas de aceitar em 500 ms: " + tentativas.get());
        assertTrue(tentativas.get() <= 50, "tentativas de aceitar em 500 ms: " + tentativas.get());
    }

    @Test
    void deveFecharSocketDeEscutaQuandoAceitadorParar() throws Exception {
        AtomicReference<Thread> aceitador = new AtomicReference<>();
        AtomicReference<ServerSocket> socketDeEscuta = new AtomicReference<>();
        CountDownLatch tentou = new CountDownLatch(1);
        ServidorMicrochip servidor = criarServidor(porta -> {
            ServerSocket socket = new ServerSocket(porta) {
                @Override
                public Socket accept() throws IOException {
                    aceitador.set(Thread.currentThread());
                    tentou.countDown();
                    throw new IOException("falha simulada ao aceitar conexão");
                }
            };
            socketDeEscuta.set(socket);
            return socket;
        });
        Logger logger = Logger.getLogger(ServidorMicrochip.class.getName());
        logger.setUseParentHandlers(false);
        try {
            servidor.iniciar();
            aguardar(tentou);
            aceitador.get().interrupt();
            aceitador.get().join(Duration.ofSeconds(5));
        } finally {
            logger.setUseParentHandlers(true);
        }

        assertTrue(socketDeEscuta.get().isClosed());
    }

    @Test
    void deveFalharAoIniciarEmPortaOcupada() throws IOException {
        ServidorMicrochip primeiro = iniciarServidor(VALIDO, TIMEOUT_PADRAO);
        ServidorMicrochip segundo = criarServidor(primeiro.portaLocal(), VALIDO, TIMEOUT_PADRAO);

        assertThrows(BindException.class, segundo::iniciar);
    }

    @Test
    void naoDeveIniciarDepoisDeEncerrar() {
        ServidorMicrochip servidor = criarServidor(0, VALIDO, TIMEOUT_PADRAO);
        servidor.encerrar();

        assertThrows(IllegalStateException.class, servidor::iniciar);
    }

    @Test
    void naoDeveIniciarDuasVezes() throws IOException {
        ServidorMicrochip servidor = iniciarServidor(VALIDO, TIMEOUT_PADRAO);

        assertThrows(IllegalStateException.class, servidor::iniciar);
    }

    @Test
    void deveRecusarConsultaDePortaAntesDeIniciar() {
        ServidorMicrochip servidor = criarServidor(0, VALIDO, TIMEOUT_PADRAO);

        assertThrows(IllegalStateException.class, servidor::portaLocal);
    }

    @Test
    void deveRegistrarPortaSemSeparadorDeMilhar() throws IOException {
        Logger logger = Logger.getLogger(ServidorMicrochip.class.getName());
        List<String> mensagens = new CopyOnWriteArrayList<>();
        Handler capturador = new Handler() {
            @Override
            public void publish(LogRecord registro) {
                mensagens.add(new SimpleFormatter().formatMessage(registro));
            }

            @Override
            public void flush() {
            }

            @Override
            public void close() {
            }
        };
        logger.addHandler(capturador);
        try {
            ServidorMicrochip servidor = iniciarServidor(VALIDO, TIMEOUT_PADRAO);

            String esperada = "Servidor de microchip escutando na porta " + servidor.portaLocal() + ".";
            assertTrue(mensagens.contains(esperada), () -> "mensagens registradas: " + mensagens);
        } finally {
            logger.removeHandler(capturador);
        }
    }
}
