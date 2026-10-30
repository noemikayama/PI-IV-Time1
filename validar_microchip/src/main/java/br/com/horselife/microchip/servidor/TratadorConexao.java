// ciclo de uma conexao: le uma linha, delega ao protocolo, escreve uma linha e fecha
package br.com.horselife.microchip.servidor;

import br.com.horselife.microchip.modelos.CodigoErro;
import br.com.horselife.microchip.protocolo.ProcessadorRequisicao;
import br.com.horselife.microchip.protocolo.ProcessadorRequisicao.Resultado;
import br.com.horselife.microchip.utilitarios.LeitorLinhaLimitada;
import br.com.horselife.microchip.utilitarios.LeitorLinhaLimitada.Leitura;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.logging.Level;
import java.util.logging.Logger;

final class TratadorConexao implements Runnable {

    private static final Logger LOGGER = Logger.getLogger(TratadorConexao.class.getName());
    private static final int TAMANHO_DRENO = 1024;

    private final Socket socket;
    private final Duration timeoutLeitura;
    private final ProcessadorRequisicao processador;

    TratadorConexao(Socket socket, Duration timeoutLeitura, ProcessadorRequisicao processador) {
        this.socket = socket;
        this.timeoutLeitura = timeoutLeitura;
        this.processador = processador;
    }

    @Override
    public void run() {
        String ip = socket.getInetAddress().getHostAddress();
        try (socket) {
            socket.setSoTimeout(Math.toIntExact(timeoutLeitura.toMillis()));
            BufferedReader leitor = new BufferedReader(
                    new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
            BufferedWriter escritor = new BufferedWriter(
                    new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8));
            try {
                Resultado resultado = atender(leitor);
                escrever(escritor, resultado);
                LOGGER.log(Level.INFO, "conexão ip={0} comando={1} resultado={2}",
                        new Object[] {ip, resultado.comando(), resultado.desfecho()});
            } catch (RuntimeException e) {
                LOGGER.log(Level.SEVERE, "Falha inesperada na conexão ip=" + ip, e);
                escrever(escritor, processador.erro(CodigoErro.ERRO_INTERNO));
            }
        } catch (SocketTimeoutException e) {
            LOGGER.log(Level.WARNING, "Tempo de leitura esgotado; conexão ip={0} fechada sem resposta.", ip);
        } catch (IOException e) {
            LOGGER.log(Level.WARNING, "Falha de E/S na conexão ip=" + ip, e);
        }
    }

    private Resultado atender(BufferedReader leitor) throws IOException {
        Leitura leitura = LeitorLinhaLimitada.lerLinha(leitor, ServidorMicrochip.LIMITE_CARACTERES);
        if (leitura.excedeuLimite()) {
            return processador.erro(CodigoErro.REQUISICAO_MUITO_GRANDE);
        }
        return processador.processar(leitura.linha());
    }

    private void escrever(BufferedWriter escritor, Resultado resultado) throws IOException {
        escritor.write(resultado.respostaJson());
        escritor.write('\n');
        escritor.flush();
        socket.shutdownOutput();
        drenarEntrada();
    }

    private void drenarEntrada() {
        long prazo = System.nanoTime() + timeoutLeitura.toNanos();
        byte[] descarte = new byte[TAMANHO_DRENO];
        try {
            InputStream entrada = socket.getInputStream();
            int lidos;
            do {
                lidos = entrada.read(descarte);
            } while (lidos != -1 && System.nanoTime() < prazo);
        } catch (IOException e) {
            LOGGER.log(Level.FINE, "Dreno da entrada interrompido.", e);
        }
    }
}
