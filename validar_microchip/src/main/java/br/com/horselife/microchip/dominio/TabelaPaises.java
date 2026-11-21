// tabela iso 3166-1 lida uma vez do csv para um mapa imutavel; arquivo ausente ou malformado impede a inicializacao
package br.com.horselife.microchip.dominio;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

public final class TabelaPaises {

    private static final String ARQUIVO_PADRAO = "/paises-iso3166.csv";
    private static final String CABECALHO = "codigo;nome";
    private static final String SEPARADOR = ";";
    private static final int TAMANHO_CODIGO = 3;

    private final Map<String, String> paises;

    private TabelaPaises(Map<String, String> paises) {
        this.paises = Map.copyOf(paises);
    }

    public static TabelaPaises carregar() {
        return carregar(ARQUIVO_PADRAO);
    }

    static TabelaPaises carregar(String recurso) {
        InputStream entrada = TabelaPaises.class.getResourceAsStream(recurso);
        if (entrada == null) {
            throw new IllegalStateException("Arquivo de países não encontrado no classpath: " + recurso);
        }
        try (entrada) {
            return ler(entrada);
        } catch (IOException e) {
            throw new IllegalStateException("Falha ao fechar o arquivo de países: " + recurso, e);
        }
    }

    static TabelaPaises ler(InputStream entrada) {
        BufferedReader leitor = new BufferedReader(
                new InputStreamReader(entrada, StandardCharsets.UTF_8.newDecoder()));
        try {
            if (!CABECALHO.equals(leitor.readLine())) {
                throw malformado(1, "o cabeçalho deve ser exatamente '" + CABECALHO + "'");
            }
            Map<String, String> paises = new HashMap<>();
            int numeroLinha = 1;
            String linha;
            while ((linha = leitor.readLine()) != null) {
                numeroLinha++;
                String[] colunas = linha.split(SEPARADOR, -1);
                if (colunas.length != 2) {
                    throw malformado(numeroLinha, "esperado 'codigo;nome'");
                }
                String codigo = colunas[0];
                String nome = colunas[1];
                if (!codigoValido(codigo)) {
                    throw malformado(numeroLinha, "o código '" + codigo + "' deve ter exatamente 3 dígitos");
                }
                if (nome.isBlank()) {
                    throw malformado(numeroLinha, "o nome do código " + codigo + " está vazio");
                }
                if (paises.put(codigo, nome) != null) {
                    throw malformado(numeroLinha, "o código " + codigo + " está repetido");
                }
            }
            if (paises.isEmpty()) {
                throw new IllegalStateException("Arquivo de países sem nenhum país.");
            }
            return new TabelaPaises(paises);
        } catch (IOException e) {
            throw new IllegalStateException("Não foi possível ler o arquivo de países; ele deve estar em UTF-8.", e);
        }
    }

    private static boolean codigoValido(String codigo) {
        return codigo.length() == TAMANHO_CODIGO && codigo.chars().allMatch(c -> c >= '0' && c <= '9');
    }

    private static IllegalStateException malformado(int numeroLinha, String motivo) {
        return new IllegalStateException(
                "Arquivo de países malformado na linha " + numeroLinha + ": " + motivo + ".");
    }

    public Optional<String> nome(String codigo) {
        return Optional.ofNullable(paises.get(codigo));
    }

    Set<String> codigos() {
        return paises.keySet();
    }
}
