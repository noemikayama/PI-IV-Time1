// codigos de erro de validacao e de protocolo, cada um com sua mensagem padrao
package br.com.horselife.microchip.modelos;

public enum CodigoErro {

    MICROCHIP_AUSENTE("O microchip é obrigatório."),
    FORMATO_INVALIDO("O microchip deve conter somente dígitos de 0 a 9."),
    TAMANHO_INVALIDO("O microchip deve ter exatamente 15 dígitos."),
    SEQUENCIA_REPETIDA("O microchip não pode ser uma sequência de dígitos iguais."),
    PAIS_INVALIDO("O código de país não corresponde a um país ISO 3166-1."),
    DIGITO_VERIFICADOR_INVALIDO("Os dígitos verificadores não conferem."),
    REQUISICAO_MALFORMADA("A requisição não é um JSON válido."),
    COMANDO_DESCONHECIDO("O comando informado não é suportado."),
    REQUISICAO_MUITO_GRANDE("A requisição excede o limite de 1024 caracteres."),
    ERRO_INTERNO("Erro interno no servidor.");

    private final String mensagem;

    CodigoErro(String mensagem) {
        this.mensagem = mensagem;
    }

    public String mensagem() {
        return mensagem;
    }
}
