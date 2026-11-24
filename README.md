# HorseLife

Projeto Integrador IV — Time 1

## Artefatos

| Artefato | Link |
|---|---|
| Protótipo de telas (Figma, acesso público) | [HorseLife — gratuito](https://www.figma.com/design/TBZdVCp5sBktXX2R0zUYbm/HorseLife-gratuito?node-id=0-1) |
| Protótipo de telas (Figma, plano estudante) | [HorseLife — Telas](https://www.figma.com/design/DUzSxACSKWRbl9hI1y5Pdi/HorseLife---Telas?node-id=137-2) |
| Dicionário de Dados | [Google Docs](https://docs.google.com/document/d/1xdVE_cQG7qW13HHPs0VsCIaRyhKZxfxHyO2o4jhiOlk/edit) |
| Relatório de Ideação | [Google Docs](https://docs.google.com/document/d/1xdVE_cQG7qW13HHPs0VsCIaRyhKZxfxHyO2o4jhiOlk/edit) |
| Documento de Requisitos | [Google Docs](https://docs.google.com/document/d/1t7o6FCueb-iQ6Q4J6_haDANEN_lQMljhFAXI-HXnM9c/edit) |

## Sumário

1. [Equipe](#1-equipe)
2. [Descrição](#2-descrição)
3. [Tecnologias](#3-tecnologias)
4. [Execução](#4-execução)
5. [Manutenção](#5-manutenção)

## 1. Equipe

| Nome | RA |
|---|---|
| Davi Alves Froza | 25016900 |
| Enzo Olivato Pazian | 25001654 |
| Gabriela Sichiroli Ferrari | 25013763 |
| Miguel Afonso Castro de Almeida | 25016044 |
| Noemi Kayama | 25004140 |

## 2. Descrição

O HorseLife é um aplicativo para o acompanhamento do treinamento de cavalos.
O sistema atende a dois perfis de usuário:

- **Responsável** (proprietário): cadastra os cavalos, com microchip, foto e
  histórico de saúde, vincula treinadores a eles e acompanha a evolução de cada
  animal por meio de um painel de indicadores.
- **Treinador** (profissional): mantém um perfil com experiência,
  certificações em PDF e regiões de atendimento, e organiza o trabalho com os
  cavalos vinculados.

Funcionalidades principais:

- cadastro e autenticação dos dois perfis, com recuperação de senha;
- cadastro e perfil do cavalo, com validação do microchip por um serviço Java
  dedicado;
- cadastro de exercícios (com imagens e vídeos curtos), de treinamentos
  compostos por exercícios e de planos de treinamento com período definido;
- agenda semanal de treinos, registro da execução e feedback do responsável;
- avaliações do cavalo e painel com indicadores por período.

## 3. Tecnologias

| Componente | Diretório | Tecnologias |
|---|---|---|
| Aplicativo | [horse_life/](horse_life/) | Flutter / Dart |
| Backend | [functions/](functions/) | Firebase Cloud Functions, TypeScript, Node.js 24 |
| Banco de dados | — | MongoDB Atlas |
| Armazenamento de arquivos | — | Firebase Cloud Storage |
| Autenticação | — | Firebase Authentication (e-mail e senha) |
| Validação de microchip | [validar_microchip/](validar_microchip/) | Java 25, Maven, servidor TCP |

```
Aplicativo Flutter ──▶ Cloud Functions ──▶ MongoDB Atlas
                             │  └────────▶ Cloud Storage
                             └──TCP──────▶ Servidor Java de microchip
```

A documentação de arquitetura e os contratos das funções encontram-se em
[docs/](docs/).

## 4. Execução

Executa o aplicativo, as Cloud Functions no emulador do Firebase e o servidor
Java de microchip na máquina local:

```
Aplicativo ──callable──▶ Functions no emulador (127.0.0.1:5001) ──TCP──▶ Servidor Java (127.0.0.1:7700)
```

Apenas as Cloud Functions são emuladas: autenticação, banco de dados e
armazenamento continuam sendo os do projeto publicado, portanto os dados
cadastrados são gravados no banco real. Para acessar o aplicativo, crie uma
conta pelo próprio aplicativo (cadastro de responsável ou de treinador) ou
utilize a conta de teste informada pela equipe.

### 4.1. Arquivos fornecidos pela equipe

A execução exige **dois arquivos entregues pela equipe à parte**, fora do
repositório, pois concedem acesso ao banco de dados e ao projeto Firebase:

| Arquivo | Local de destino |
|---|---|
| `.secret.local` (com `MONGODB_URI` e `WEB_API_KEY`) | pasta `functions/` do repositório, sem edição |
| chave da conta de serviço (`.json`) | qualquer pasta **fora** do repositório, por exemplo `~/chaves/horselife-admin.json` |

- O `.secret.local` é obrigatório. Sem ele, o emulador tenta ler os segredos
  do Secret Manager, e a leitura falha.
- Sem a chave da conta de serviço, o emulador não consegue assinar o token de
  login, e o aplicativo exibe "Erro de conexão com o servidor" (no terminal 2
  aparece `Failed to determine service account`). A mesma chave permite gerar
  as URLs assinadas de envio e leitura de imagens.
- Ambos concedem acesso administrativo ao projeto: não os compartilhe nem os
  inclua no repositório.

Não é necessário possuir conta no Firebase, executar `firebase login` nem
instalar o `gcloud`. Sem autenticação, o emulador exibe avisos como
`You are not currently authenticated` e
`Unable to fetch project Admin SDK configuration`, que podem ser ignorados.

### 4.2. Pré-requisitos

| Ferramenta | Versão / observação |
|---|---|
| [Git](https://git-scm.com/) | qualquer |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | canal *stable*, Dart ≥ 3.11.5 (testado com Flutter 3.47.8), com emulador Android (Android Studio) ou Google Chrome |
| [Node.js](https://nodejs.org/) | 24 (com outra versão, o emulador emite aviso e utiliza a versão instalada; testado com Node 22) |
| [Firebase CLI](https://firebase.google.com/docs/cli) | opcional: `npm install -g firebase-tools`; os comandos abaixo usam `npx firebase-tools`, que dispensa a instalação |
| [JDK](https://jdk.java.net/25/) | 25 |

Após instalar o Flutter, execute `flutter doctor` e corrija as pendências
indicadas para a plataforma de destino.

### 4.3. Configuração inicial

Realizada uma única vez.

1. **Obtenha o código-fonte.** Os comandos seguintes partem da raiz do
   repositório.

   ```bash
   git clone <url-do-repositório>
   cd PI-IV-Time1
   ```

2. **Gere o pacote do servidor de microchip.** A pasta `target/` não é
   versionada; sem este passo, o terminal 1 da seção 4.4 falha com
   `Unable to access jarfile target/servidor-microchip.jar`.

   ```bash
   cd validar_microchip
   ./mvnw clean package      # no Windows: mvnw.cmd clean package
   cd ..
   ```

3. **Instale as dependências do backend.**

   ```bash
   cd functions
   npm ci
   cd ..
   ```

4. **Posicione os arquivos fornecidos pela equipe**, conforme a
   [seção 4.1](#41-arquivos-fornecidos-pela-equipe).

5. **Crie o arquivo `functions/.env.local`** com o conteúdo abaixo. O arquivo
   não é versionado (regra `*.local`) e é lido apenas pelo emulador.

   ```
   MONGODB_DB=horseLife
   MICROCHIP_HOST=127.0.0.1
   MICROCHIP_PORTA=7700
   ```

   - O nome do banco diferencia maiúsculas de minúsculas. Com outro nome (por
     exemplo, `horselife`), o MongoDB não acusa erro, mas lê um banco vazio, e o
     aplicativo exibe "Cadastro não encontrado para este e-mail" no login ou
     "Não foi possível carregar os dados da Home".
   - Mantenha as três chaves no arquivo. Se alguma estiver ausente, o CLI
     solicita o valor ao iniciar o emulador.
   - Salve o arquivo em UTF-8 sem BOM. No Windows, o Bloco de Notas e o
     PowerShell podem gravá-lo com BOM ou em UTF-16, e o emulador deixa de
     reconhecer as variáveis.

### 4.4. Inicialização

Inicie cada componente em um terminal separado, na ordem abaixo.

| Ordem | Diretório | Comando | Indicação de prontidão |
|---|---|---|---|
| 1 | `validar_microchip/` | `java -jar target/servidor-microchip.jar` | `Servidor de microchip escutando na porta 7700.` |
| 2 | `functions/` | `npm run build && GOOGLE_APPLICATION_CREDENTIALS="$HOME/chaves/horselife-admin.json" npx firebase-tools emulators:start --only functions` | URL `.../southamerica-east1/validateMicrochip` e `All emulators ready!` |
| 3 | `horse_life/` | `flutter run -d chrome --dart-define=FUNCTIONS_EMULATOR_HOST=127.0.0.1` | abertura do aplicativo |

- Terminal 1: sempre que o código Java mudar, rode antes `./mvnw clean package`.
- **Terminal 2:** substitua o caminho pelo local em que a chave da conta de
  serviço foi salva. A variável vale apenas para o comando em que é informada,
  portanto utilize sempre a linha completa. Confira o caminho com
  `ls "<caminho>"`: um caminho com variável indefinida (como `$nome/...`) fica
  incorreto sem nenhum aviso.
- **Terminal 2 no Windows (PowerShell):**
  `$env:GOOGLE_APPLICATION_CREDENTIALS="C:\chaves\horselife-admin.json"; npm run build; npx firebase-tools emulators:start --only functions`
- **Terminal 2:** inicie sempre com `--only functions`. Sem essa opção, o
  emulador de autenticação também é iniciado, vazio, e todo login retorna
  "E-mail ou senha inválidos".
- Após alterar o `.env.local` ou o `.secret.local`, encerre o terminal 2 com
  `Ctrl+C` e inicie-o novamente: os arquivos são lidos apenas na inicialização.

O comando do terminal 3 executa o aplicativo no Chrome. Para outros
dispositivos, ajuste o `-d` e o endereço do emulador:

| Dispositivo | Comando do terminal 3 |
|---|---|
| Navegador (Chrome) | `flutter run -d chrome --dart-define=FUNCTIONS_EMULATOR_HOST=127.0.0.1` |
| Emulador Android | `flutter run -d emulator --dart-define=FUNCTIONS_EMULATOR_HOST=10.0.2.2` |
| Simulador iOS (somente macOS) | `flutter run -d <id do simulador> --dart-define=FUNCTIONS_EMULATOR_HOST=127.0.0.1` |
| Dispositivo físico na mesma rede | `flutter run -d <id do dispositivo> --dart-define=FUNCTIONS_EMULATOR_HOST=<IP da máquina na rede>`; adicione também `"host": "0.0.0.0"` em `emulators.functions` no `firebase.json`, sem versionar a alteração |

O comando `flutter devices` lista os dispositivos disponíveis e seus
identificadores. O dispositivo deve ser sempre informado com `-d`: sem ele, o
Flutter pode escolher outro dispositivo. No Linux, por exemplo, escolhe a
versão *desktop*, que não é suportada, e o aplicativo para na tela de abertura
com erro de inicialização. Plataformas suportadas: Android, web, iOS e macOS.

### 4.5. Verificação

Com os três terminais em execução, faça login como responsável e siga o
cadastro de cavalo até a etapa do microchip:

| Ação | Resultado esperado |
|---|---|
| Informar `076987654321017` | o cadastro avança; o terminal 1 registra `resultado=VALIDO` |
| Informar `076987654321018` | "Código inválido": "Os dígitos verificadores não conferem." |
| Informar `999123456789004` | "Código inválido": "O código de país não corresponde a um país ISO 3166-1." |
| Encerrar o terminal 1 e informar `076987654321017` | "Erro na validação": "Não foi possível validar o microchip. Tente novamente."; nada é gravado |
| Reiniciar o terminal 1 e concluir o cadastro | o cavalo é salvo; um novo cadastro com o mesmo microchip retorna "Este microchip já está cadastrado." |

O protocolo do servidor, os testes manuais sem o aplicativo e as limitações do
ambiente local estão descritos em
[validar_microchip/README.md](validar_microchip/README.md).

## 5. Manutenção

As tarefas abaixo exigem acesso ao projeto Firebase `horselife-2717b`.

### 5.1. Geração do `.secret.local`

Autentique o [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) e
gere o arquivo diretamente a partir da saída do `gcloud`, sem copiar e colar,
para evitar espaços ou aspas indevidos. Execute dentro de `functions/`:

```bash
# macOS ou Linux
gcloud auth login
{ echo "MONGODB_URI=$(gcloud secrets versions access latest --secret=MONGODB_URI --project horselife-2717b)"; echo "WEB_API_KEY=$(gcloud secrets versions access latest --secret=WEB_API_KEY --project horselife-2717b)"; } > .secret.local
```

```powershell
# Windows (PowerShell): grava em UTF-8 sem BOM
gcloud auth login
$uri = gcloud secrets versions access latest --secret=MONGODB_URI --project horselife-2717b
$key = gcloud secrets versions access latest --secret=WEB_API_KEY --project horselife-2717b
[IO.File]::WriteAllText("$PWD\.secret.local", "MONGODB_URI=$uri`nWEB_API_KEY=$key`n", (New-Object Text.UTF8Encoding $false))
```

A `WEB_API_KEY` correta tem 39 caracteres e começa com `AIza`. Com uma chave
incorreta, todo login retorna "E-mail ou senha inválidos", mesmo com a senha
correta.

### 5.2. Geração da chave da conta de serviço

No Console do Firebase, acesse **Configurações do projeto** → **Contas de
serviço** → **Gerar nova chave privada** (conta
`firebase-adminsdk-…@horselife-2717b.iam.gserviceaccount.com`). Exige papel de
proprietário ou editor do projeto.

Salve o `.json` fora do repositório. A chave concede acesso de administrador a
todo o projeto: após o período de avaliação, revogue as chaves entregues em
**Google Cloud Console** → **IAM e administrador** → **Contas de serviço** →
**Chaves**.

### 5.3. Testes

| Componente | Diretório | Comando |
|---|---|---|
| Aplicativo | `horse_life/` | `flutter test` |
| Backend | `functions/` | `npm test` |
| Servidor de microchip | `validar_microchip/` | `./mvnw test` |

### 5.4. Publicação do backend

Exige `firebase login` com uma conta com permissão no projeto. As etapas de
*lint* e compilação são executadas automaticamente antes do envio.

```bash
cd functions
npm run deploy
```
