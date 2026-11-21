// ponto de entrada: le a porta, monta as dependencias e inicia o servidor
package br.com.horselife.microchip;

import br.com.horselife.microchip.dominio.TabelaPaises;
import br.com.horselife.microchip.dominio.ValidadorMicrochip;
import br.com.horselife.microchip.modelos.Validador;
import br.com.horselife.microchip.protocolo.ProcessadorRequisicao;
import br.com.horselife.microchip.servidor.ServidorMicrochip;
import java.io.IOException;
import java.time.Duration;
import java.util.logging.Level;
import java.util.logging.Logger;

public final class Main {

    private static final Logger LOGGER = Logger.getLogger(Main.class.getName());

    static final int PORTA_PADRAO = 7700;
    private static final Duration TIMEOUT_LEITURA = Duration.ofSeconds(5);
    private static final int PORTA_MINIMA = 1;
    private static final int PORTA_MAXIMA = 65535;

    private Main() {
    }

    public static void main(String[] args) {
        int porta;
        try {
            porta = resolverPorta(System.getenv("MICROCHIP_PORTA"));
        } catch (IllegalArgumentException e) {
            LOGGER.log(Level.SEVERE, "Falha ao iniciar: {0}", e.getMessage());
            System.exit(1);
            return;
        }

        TabelaPaises tabelaPaises;
        try {
            tabelaPaises = TabelaPaises.carregar();
        } catch (IllegalStateException e) {
            LOGGER.log(Level.SEVERE, "Falha ao iniciar: {0}", e.getMessage());
            System.exit(1);
            return;
        }
        Validador validador = new ValidadorMicrochip(tabelaPaises);

        ServidorMicrochip servidor =
                new ServidorMicrochip(porta, TIMEOUT_LEITURA, new ProcessadorRequisicao(validador));
        try {
            servidor.iniciar();
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE, "Falha ao iniciar: não foi possível abrir a porta " + porta + ".", e);
            System.exit(1);
            return;
        }
        Runtime.getRuntime().addShutdownHook(new Thread(servidor::encerrar, "encerramento-microchip"));
    }

    static int resolverPorta(String valor) {
        if (valor == null) {
            return PORTA_PADRAO;
        }
        if (valor.isEmpty() || valor.length() > 5 || !somenteDigitos(valor)) {
            throw portaInvalida(valor);
        }
        int porta = Integer.parseInt(valor);
        if (porta < PORTA_MINIMA || porta > PORTA_MAXIMA) {
            throw portaInvalida(valor);
        }
        return porta;
    }

    private static boolean somenteDigitos(String valor) {
        return valor.chars().allMatch(c -> c >= '0' && c <= '9');
    }

    private static IllegalArgumentException portaInvalida(String valor) {
        return new IllegalArgumentException(
                "MICROCHIP_PORTA inválida: '" + valor + "'. Use um inteiro entre "
                        + PORTA_MINIMA + " e " + PORTA_MAXIMA + ".");
    }
}
