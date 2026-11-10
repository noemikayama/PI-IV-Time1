// le uma unica linha de um reader sem guardar mais que o limite de caracteres
package br.com.horselife.microchip.utilitarios;

import java.io.IOException;
import java.io.Reader;

public final class LeitorLinhaLimitada {

    public record Leitura(String linha, boolean excedeuLimite) {
    }

    private LeitorLinhaLimitada() {
    }

    public static Leitura lerLinha(Reader leitor, int limiteCaracteres) throws IOException {
        if (limiteCaracteres <= 0) {
            throw new IllegalArgumentException("O limite de caracteres deve ser positivo.");
        }

        StringBuilder linha = new StringBuilder();
        int caractere;
        while ((caractere = leitor.read()) != -1 && caractere != '\n') {
            if (linha.length() > limiteCaracteres) {
                return new Leitura(null, true);
            }
            linha.append((char) caractere);
        }

        if (!linha.isEmpty() && linha.charAt(linha.length() - 1) == '\r') {
            linha.setLength(linha.length() - 1);
        }
        if (linha.length() > limiteCaracteres) {
            return new Leitura(null, true);
        }
        return new Leitura(linha.toString(), false);
    }
}
