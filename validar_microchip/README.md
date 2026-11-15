# Servidor de Validação de Microchip (HorseLife)

## 1. Propósito

Microsserviço TCP do projeto HorseLife com uma única responsabilidade: receber o número de microchip de um cavalo e dizer se ele é válido. Em geral, quem o chama é uma Firebase Function.

O servidor valida, nesta ordem:

1. presença do valor;
2. somente dígitos `0`–`9`;
3. exatamente 15 dígitos;
4. não ser uma sequência de dígitos todos iguais;
5. código de país (3 primeiros dígitos) ISO 3166-1 numérico;
6. 1º dígito verificador;
7. 2º dígito verificador.

Fora do escopo: banco de dados, verificação de unicidade do microchip (feita pelo backend), HTTP e remoção de formatação. Pontos, hífens e espaços devem ser removidos pelo app antes do envio.

## 2. Como compilar e rodar

Requisitos: **JDK 25**. O Maven não precisa estar instalado: o projeto usa o wrapper `./mvnw` (no Windows, `mvnw.cmd`), que baixa a versão certa do Maven na primeira execução.

Todos os comandos são executados na raiz do módulo (`validar_microchip/`).

```bash
./mvnw clean test       # compila e roda os testes
./mvnw clean package    # gera o JAR executável em target/servidor-microchip.jar

java -jar target/servidor-microchip.jar                        # sobe na porta 7700
MICROCHIP_PORTA=7800 java -jar target/servidor-microchip.jar   # sobe em outra porta
```

| Configuração | Valor |
|---|---|
| Porta padrão | `7700` |
| Sobrescrita da porta | variável de ambiente `MICROCHIP_PORTA` (inteiro de 1 a 65535) |
| Timeout de leitura | 5 segundos |
| Limite da requisição | 1024 caracteres |

O servidor registra o erro e encerra com código de saída `1`, sem atender nenhuma conexão, quando:

- `MICROCHIP_PORTA` é inválida (por exemplo `abc`, `0`, `+7800` ou com espaços);
- a porta já está em uso;
- a tabela de países (`paises-iso3166.csv`, que vai dentro do JAR) está ausente ou malformada. Veja a seção 6.

Para parar o servidor, use `Ctrl+C` ou `kill <pid>`. As requisições em andamento terminam antes de o processo sair, e novas conexões são recusadas.

## 3. Protocolo

- **Transporte:** TCP puro.
- **Codificação:** UTF-8.
- **Enquadramento:** um objeto JSON por linha, terminado em `\n` (JSON Lines). O JSON não pode conter quebras de linha.
- **Ciclo da conexão:** uma requisição por conexão. O cliente conecta, envia uma linha e recebe uma linha, e o servidor fecha a conexão.
- **Limite:** linhas com mais de 1024 caracteres recebem `REQUISICAO_MUITO_GRANDE`.
- **Timeout:** se o cliente passar 5 segundos sem enviar dados antes de completar a linha, a conexão é fechada **sem resposta**. O prazo recomeça a cada dado recebido, então não é um limite para a requisição inteira.
- O campo `microchip` deve ser uma **string** JSON. Um número (`"microchip": 76987654321017`) é recusado com `REQUISICAO_MALFORMADA`, porque perderia o zero à esquerda do código do país (o Brasil é `076`).
- Campos desconhecidos na requisição são ignorados.

### Requisição

```json
{"comando":"VALIDAR_MICROCHIP","microchip":"076987654321017"}
```

### Respostas

**Microchip válido**

```json
{"valido":true,"microchip":"076987654321017","codigoPais":"076","nomePais":"Brasil"}
```

**Microchip inválido** (regra de negócio)

```json
{"valido":false,"microchip":"076987654321018","erro":{"codigo":"DIGITO_VERIFICADOR_INVALIDO","mensagem":"Os dígitos verificadores não conferem."}}
```

**Erro de protocolo** (a requisição não pôde ser interpretada; o campo `microchip` é omitido)

```json
{"valido":false,"erro":{"codigo":"REQUISICAO_MALFORMADA","mensagem":"A requisição não é um JSON válido."}}
```

Campos nulos nunca são enviados.

### Códigos de erro

| Código | Tipo | Quando |
|---|---|---|
| `MICROCHIP_AUSENTE` | validação | O microchip é nulo ou vazio. |
| `FORMATO_INVALIDO` | validação | Há caracteres além de `0`–`9`. |
| `TAMANHO_INVALIDO` | validação | Não tem exatamente 15 dígitos. |
| `SEQUENCIA_REPETIDA` | validação | Todos os dígitos são iguais (ex.: `111111111111111`). |
| `PAIS_INVALIDO` | validação | Os 3 primeiros dígitos não são um país ISO 3166-1. |
| `DIGITO_VERIFICADOR_INVALIDO` | validação | O 1º ou o 2º dígito verificador não confere. |
| `REQUISICAO_MALFORMADA` | protocolo | JSON inválido, linha vazia, `comando` ausente ou campo com tipo errado. |
| `COMANDO_DESCONHECIDO` | protocolo | O `comando` é diferente de `VALIDAR_MICROCHIP`. |
| `REQUISICAO_MUITO_GRANDE` | protocolo | A linha excede 1024 caracteres. |
| `ERRO_INTERNO` | protocolo | Erro inesperado no servidor. Os detalhes ficam só no log do servidor. |

## 4. Teste manual

Com o servidor rodando em outro terminal:

```bash
echo '{"comando":"VALIDAR_MICROCHIP","microchip":"076987654321017"}' | nc localhost 7700
echo '{"comando":"VALIDAR_MICROCHIP","microchip":"076987654321018"}' | nc localhost 7700
echo '{"comando":"X"}' | nc localhost 7700
echo 'não é json' | nc localhost 7700
```

Respostas esperadas:

```json
{"valido":true,"microchip":"076987654321017","codigoPais":"076","nomePais":"Brasil"}
{"valido":false,"microchip":"076987654321018","erro":{"codigo":"DIGITO_VERIFICADOR_INVALIDO","mensagem":"Os dígitos verificadores não conferem."}}
{"valido":false,"erro":{"codigo":"COMANDO_DESCONHECIDO","mensagem":"O comando informado não é suportado."}}
{"valido":false,"erro":{"codigo":"REQUISICAO_MALFORMADA","mensagem":"A requisição não é um JSON válido."}}
```

No Fedora, o `nc` é o `nmap-ncat`: ele envia a linha, recebe a resposta e sai sozinho. Se outra variante do netcat não sair sozinha, pressione `Ctrl+C`; o que importa é a linha recebida.

## 5. Aviso: a regra dos dígitos verificadores não é a da ISO 11784

Microchips equinos reais seguem a **ISO 11784/11785**: 15 dígitos, sendo 3 de país e 12 de identificação. Esse número **não tem dígito verificador**, porque a integridade é garantida por CRC na transmissão por radiofrequência.

Neste projeto, o formato é diferente:

```
 P P P  I I I I I I I I I I  D D
 └─┬─┘  └────────┬────────┘  └┬┘
 país    identificação (10)   DVs
 (3)                          (2)
```

Os dois últimos dígitos são verificadores, calculados por uma **adaptação acadêmica da regra do CPF** definida pelo projeto (pesos de 14 a 2 para o DV1 e de 15 a 2 para o DV2, módulo 11). Por isso, **a maioria dos microchips reais seria rejeitada** por este servidor.

## 6. Tabela de países

A regra 5 confere os 3 primeiros dígitos com o arquivo `src/main/resources/paises-iso3166.csv`, que vai dentro do JAR. O servidor lê o arquivo uma única vez, na inicialização, e não usa nenhuma biblioteca de países.

- **Conteúdo:** os **249 códigos** numéricos atribuídos pela ISO 3166-1 a países e territórios, com o nome em português. Exemplo: `076;Brasil`.
- **Formato:** UTF-8 sem BOM. A primeira linha é exatamente `codigo;nome`, e depois vem uma linha `ddd;Nome` por código, em ordem de código. O código tem sempre 3 dígitos, com zeros à esquerda.
- **Leitura estrita:** qualquer desvio desse formato impede a inicialização: cabeçalho diferente, `,` no lugar de `;`, coluna a mais, código sem 3 dígitos (`76;Brasil`), nome vazio, código repetido, linha em branco, BOM, arquivo fora de UTF-8 ou nenhum país. Nos erros de formato, a mensagem indica a linha. Esses são os defeitos típicos de um CSV salvo numa planilha. Finais de linha `\r\n` e a falta do `\n` final são aceitos.
- **Origem:** gerado em 2026-11-12. Os códigos vêm do pacote `iso-codes` 4.20.1 (Debian/Fedora), que acompanha a agência de manutenção da ISO 3166. Os nomes são os do CLDR em português do Brasil, como o JDK 25 os fornece; cada nome é associado ao seu código numérico pelo código alfa-2 (por exemplo, `BR` → `076`). Os códigos foram conferidos com a tabela M49 da ONU. O arquivo não tem edição manual: para atualizá-lo, gere-o de novo a partir das mesmas fontes.

Recebem `PAIS_INVALIDO`, porque não representam um país:

- a faixa **900–999**, reservada para uso do usuário (na ISO 11784, os códigos 900–998 identificam o fabricante, não o país);
- os códigos **não atribuídos**, como `000`;
- os códigos **regionais da ONU (M49)**, que não fazem parte da ISO 3166-1, como `001` (Mundo), `019` (Américas) e `419` (América Latina e Caribe).

## Limitação conhecida

Ao encerrar com `Ctrl+C` ou `kill`, as linhas de log escritas depois do sinal podem não aparecer (por exemplo, `Servidor de microchip encerrado.`). O `java.util.logging` registra o próprio *shutdown hook*, que fecha a saída do log, e a JVM executa os *hooks* em paralelo, sem ordem definida. O encerramento continua gracioso: as requisições em andamento terminam e novas conexões são recusadas. Só essas linhas de log se perdem.
