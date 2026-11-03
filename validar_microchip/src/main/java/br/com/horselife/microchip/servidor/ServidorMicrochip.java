// servidor tcp: aceita conexoes e atende cada uma numa thread virtual propria
package br.com.horselife.microchip.servidor;

import br.com.horselife.microchip.protocolo.ProcessadorRequisicao;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.RejectedExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

public final class ServidorMicrochip implements AutoCloseable {

    static final int LIMITE_CARACTERES = 1024;

    private static final Logger LOGGER = Logger.getLogger(ServidorMicrochip.class.getName());
    private static final long ESPERA_ENCERRAMENTO_SEGUNDOS = 10;
    private static final Duration PAUSA_APOS_FALHA = Duration.ofMillis(100);

    private final int porta;
    private final Duration timeoutLeitura;
    private final ProcessadorRequisicao processador;
    private final FabricaServidorSocket fabricaSocket;
    private final ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();
    private final Object trava = new Object();
    private ServerSocket servidorSocket;
    private Thread aceitador;
    private boolean encerrado;

    @FunctionalInterface
    interface FabricaServidorSocket {
        ServerSocket abrir(int porta) throws IOException;
    }

    public ServidorMicrochip(int porta, Duration timeoutLeitura, ProcessadorRequisicao processador) {
        this(porta, timeoutLeitura, processador, ServerSocket::new);
    }

    ServidorMicrochip(int porta, Duration timeoutLeitura, ProcessadorRequisicao processador,
            FabricaServidorSocket fabricaSocket) {
        this.porta = porta;
        this.timeoutLeitura = timeoutLeitura;
        this.processador = processador;
        this.fabricaSocket = fabricaSocket;
    }

    public void iniciar() throws IOException {
        synchronized (trava) {
            if (servidorSocket != null || encerrado) {
                throw new IllegalStateException("O servidor já foi iniciado ou encerrado.");
            }
            ServerSocket socket = fabricaSocket.abrir(porta);
            servidorSocket = socket;
            aceitador = Thread.ofPlatform()
                    .name("aceitador-microchip")
                    .daemon(false)
                    .start(() -> aceitarConexoes(socket));
            LOGGER.log(Level.INFO, "Servidor de microchip escutando na porta {0}.",
                    String.valueOf(socket.getLocalPort()));
        }
    }

    public int portaLocal() {
        synchronized (trava) {
            if (servidorSocket == null) {
                throw new IllegalStateException("O servidor ainda não foi iniciado.");
            }
            return servidorSocket.getLocalPort();
        }
    }

    private void aceitarConexoes(ServerSocket socketDeEscuta) {
        try {
            while (!socketDeEscuta.isClosed()) {
                Socket socket;
                try {
                    socket = socketDeEscuta.accept();
                } catch (IOException e) {
                    if (socketDeEscuta.isClosed()) {
                        break;
                    }
                    LOGGER.log(Level.WARNING, "Falha ao aceitar conexão.", e);
                    if (!pausarAposFalha()) {
                        break;
                    }
                    continue;
                }
                try {
                    executor.execute(new TratadorConexao(socket, timeoutLeitura, processador));
                } catch (RejectedExecutionException e) {
                    fecharSilenciosamente(socket);
                }
            }
        } finally {
            fecharSilenciosamente(socketDeEscuta);
        }
    }

    private static boolean pausarAposFalha() {
        try {
            Thread.sleep(PAUSA_APOS_FALHA);
            return true;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return false;
        }
    }

    public void encerrar() {
        ServerSocket socket;
        Thread threadAceitadora;
        synchronized (trava) {
            if (encerrado) {
                return;
            }
            encerrado = true;
            socket = servidorSocket;
            threadAceitadora = aceitador;
        }
        if (socket != null) {
            fecharSilenciosamente(socket);
        }
        try {
            if (threadAceitadora != null) {
                threadAceitadora.join(Duration.ofSeconds(ESPERA_ENCERRAMENTO_SEGUNDOS));
            }
            executor.shutdown();
            if (!executor.awaitTermination(ESPERA_ENCERRAMENTO_SEGUNDOS, TimeUnit.SECONDS)) {
                LOGGER.warning("Conexões não terminaram a tempo; interrompendo.");
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
            Thread.currentThread().interrupt();
        }
        LOGGER.info("Servidor de microchip encerrado.");
    }

    @Override
    public void close() {
        encerrar();
    }

    private static void fecharSilenciosamente(AutoCloseable recurso) {
        try {
            recurso.close();
        } catch (Exception e) {
            LOGGER.log(Level.FINE, "Falha ao fechar recurso.", e);
        }
    }
}
