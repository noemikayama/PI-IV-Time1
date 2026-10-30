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
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.logging.Level;
import java.util.logging.Logger;

public final class ServidorMicrochip implements AutoCloseable {

    static final int LIMITE_CARACTERES = 1024;

    private static final Logger LOGGER = Logger.getLogger(ServidorMicrochip.class.getName());
    private static final long ESPERA_ENCERRAMENTO_SEGUNDOS = 10;

    private final int porta;
    private final Duration timeoutLeitura;
    private final ProcessadorRequisicao processador;
    private final ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();
    private final AtomicBoolean encerrado = new AtomicBoolean(false);
    private volatile ServerSocket servidorSocket;

    public ServidorMicrochip(int porta, Duration timeoutLeitura, ProcessadorRequisicao processador) {
        this.porta = porta;
        this.timeoutLeitura = timeoutLeitura;
        this.processador = processador;
    }

    public void iniciar() throws IOException {
        servidorSocket = new ServerSocket(porta);
        Thread.ofPlatform()
                .name("aceitador-microchip")
                .daemon(false)
                .start(this::aceitarConexoes);
        LOGGER.log(Level.INFO, "Servidor de microchip escutando na porta {0}.", String.valueOf(portaLocal()));
    }

    public int portaLocal() {
        return servidorSocket.getLocalPort();
    }

    private void aceitarConexoes() {
        while (!servidorSocket.isClosed()) {
            Socket socket;
            try {
                socket = servidorSocket.accept();
            } catch (IOException e) {
                if (servidorSocket.isClosed()) {
                    break;
                }
                LOGGER.log(Level.WARNING, "Falha ao aceitar conexão.", e);
                continue;
            }
            try {
                executor.execute(new TratadorConexao(socket, timeoutLeitura, processador));
            } catch (RejectedExecutionException e) {
                fecharSilenciosamente(socket);
            }
        }
    }

    public void encerrar() {
        if (!encerrado.compareAndSet(false, true)) {
            return;
        }
        if (servidorSocket != null) {
            fecharSilenciosamente(servidorSocket);
        }
        executor.shutdown();
        try {
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
