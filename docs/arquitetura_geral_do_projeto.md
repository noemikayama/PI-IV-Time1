# Arquitetura geral do projeto

## Arquitetura de frontend do HorseLife

### 1. Objetivo

Este documento define uma arquitetura de referência para o frontend Flutter do
HorseLife. O gerenciamento de estado utiliza recursos nativos do framework,
principalmente `StatefulWidget`, `State`, `setState()`, `InheritedWidget` e
injeção por construtor.

A arquitetura é organizada por feature e não depende de um pacote externo de
gerenciamento de estado. A intenção não é reproduzir as interfaces de outro
gerenciador manualmente, mas adotar decisões arquiteturais que continuem
válidas caso a ferramenta de estado mude no futuro:

- organização prioritariamente por feature;
- separação entre apresentação, fluxo de aplicação e acesso a dados;
- modelos tipados em vez de mapas soltos na interface;
- repositories escondendo Firebase, HTTP, banco local ou outro SDK;
- dependências recebidas, não criadas no meio da regra de negócio;
- estado pertencendo ao menor dono correto;
- operações assíncronas com estados explícitos de carregamento, sucesso e erro;
- widgets sem acesso direto a Firebase ou serialização de respostas;
- testes atravessando as mesmas interfaces usadas pela aplicação.

`setState()` é apenas o mecanismo que avisa ao Flutter que o estado local de
um widget mudou. Ele não deve definir onde ficam regras de negócio, acesso a
dados ou decisões de arquitetura.

---

### 2. Visão geral da arquitetura do HorseLife

O HorseLife deve separar a composição global, os recursos compartilhados e as
features do domínio. Uma visão resumida é:

```text
lib/
├── app/
├── core/
├── features/
│   ├── authentication/
│   │   ├── application/
│   │   ├── data/
│   │   └── presentation/
│   ├── animals/
│   ├── appointments/
│   └── profile/
└── main.dart
```

As principais qualidades esperadas são:

1. **Organização por feature.** Autenticação, perfil e agenda mantêm a maior
   parte de seus arquivos próximos.
2. **Repositories como seam de infraestrutura.** A apresentação não precisa
   conhecer detalhes de Firebase Auth, Firestore, Cloud Functions ou Storage.
3. **Adapters substituíveis.** A implementação Firebase pode ser trocada por
   um fake em testes.
4. **Modelos tipados.** Conversão de mapas, normalização e serialização não são
   feitas dentro das telas.
5. **Controllers de aplicação.** Operações como login, atualização de perfil e
   troca de senha possuem um ponto central de orquestração.
6. **Widgets compartilhados com responsabilidade definida.** Elementos
   realmente reutilizados são extraídos; detalhes exclusivos continuam dentro
   da feature.
7. **Autorização separada da apresentação.** A tela pode esconder uma ação,
   mas a autoridade continua no backend e nas regras de segurança.

---

### 3. Princípios

#### 3.1 Organizar por feature antes de organizar por tipo

Arquivos que mudam juntos devem permanecer próximos. Uma alteração no perfil
deve ser encontrada principalmente em `features/profile/`, não espalhada entre
pastas globais de telas, modelos, repositories e serviços.

#### 3.2 `setState()` pertence à apresentação

Somente widgets ou objetos `State` chamam `setState()`. Models, repositories,
adapters e controllers de aplicação não recebem `BuildContext` nem callbacks
de `setState`.

#### 3.3 O estado pertence ao menor dono correto

Coloque o estado no widget mais baixo que precisa coordená-lo:

- visibilidade de senha: no widget ou tela que mostra o campo;
- aba selecionada: na tela que contém as abas;
- dados de um formulário: na tela ou no widget de formulário;
- etapa de um cadastro: no widget pai que coordena todas as etapas;
- sessão autenticada: no gate raiz da aplicação;
- escala de fonte global: acima de toda a árvore que precisa reagir a ela.

Subir estado sem necessidade aumenta parâmetros, rebuilds e acoplamento.
Duplicar o mesmo estado em dois widgets cria fontes de verdade concorrentes.

#### 3.4 Separar estado de interface de regra de negócio

O `State` pode possuir:

- `TextEditingController`;
- `FocusNode`;
- `AnimationController`;
- `GlobalKey<FormState>`;
- booleanos visuais;
- item selecionado;
- estado imutável da tela;
- `StreamSubscription` pertencente à tela;
- flags como `_isLoading` ou `_isSubmitting`.

O `State` não deve implementar:

- leitura e escrita de Firestore;
- chamadas HTTP ou Cloud Functions;
- montagem de caminhos de Storage espalhada pela interface;
- regras de autorização;
- conversão extensa de JSON/mapas;
- algoritmos de negócio;
- tratamento específico de códigos de SDK em vários lugares.

#### 3.5 Uma fonte de verdade por dado

Dados remotos são carregados por um único fluxo. Um formulário pode criar uma
cópia editável temporária, mas deve saber claramente quando ela nasce, quando é
descartada e quando o valor remoto volta a ser a fonte de verdade.

#### 3.6 Dependências entram por construtor

Uma tela, controller ou repository não deve procurar dependências em variáveis
globais. Receba-as explicitamente:

```dart
class ProfileController {
  const ProfileController(this._repository);

  final ProfileRepository _repository;
}
```

Em produção, a raiz cria o adapter real. Em testes, injeta um fake.

#### 3.7 Criar interfaces apenas onde existe variação real

Uma interface de repository é útil quando existem pelo menos dois adapters
relevantes, normalmente:

- adapter de produção, como `FirebaseProfileRepository`;
- adapter de teste, como `FakeProfileRepository`.

Não crie uma interface e cinco arquivos apenas para esconder uma única linha
que nunca varia.

---

### 4. Estrutura recomendada

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── app_dependencies.dart
│   ├── app_gate.dart
│   └── theme/
│       ├── app_colors.dart
│       └── app_theme.dart
├── core/
│   ├── errors/
│   │   ├── app_exception.dart
│   │   └── error_mapper.dart
│   ├── firebase/
│   │   ├── firebase_bootstrap.dart
│   │   └── firebase_functions_client.dart
│   ├── extensions/
│   ├── formatters/
│   ├── validators/
│   └── widgets/
│       ├── app_error_view.dart
│       └── app_loading_indicator.dart
└── features/
    └── <feature>/
        ├── application/
        │   ├── controllers/
        │   └── states/
        ├── data/
        │   ├── models/
        │   ├── remote/                  # opcional
        │   └── repositories/
        └── presentation/
            ├── screens/
            │   ├── guardian/
            │   └── trainer/
            └── widgets/
```

Nem toda feature precisa começar com todos esses diretórios. Criar um diretório
quando existir uma responsabilidade real para colocar nele.

---

### 5. O que vai em cada diretório

#### `lib/main.dart`

É o ponto de entrada e deve permanecer pequeno.

Responsabilidades permitidas:

- chamar `WidgetsFlutterBinding.ensureInitialized()`;
- inicializar recursos obrigatórios antes do primeiro frame;
- criar as dependências de produção;
- chamar `runApp()`.

Não coloque navegação, telas, regras de negócio ou leitura de dados aqui.

#### `lib/app/`

Contém a composição global da aplicação.

##### `app.dart`

- cria `MaterialApp`;
- aplica tema, locale e escala global;
- configura a navegação;
- entrega dependências estáveis à árvore;
- monta o gate inicial.

##### `app_dependencies.dart`

É a composição das dependências de produção, não um depósito de estado
mutável.

```dart
class AppDependencies {
  const AppDependencies({
    required this.authRepository,
    required this.profileRepository,
  });

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
}
```

As dependências podem ser passadas por construtor. Se o aplicativo for grande,
um `InheritedWidget` pode expor esse objeto estável para evitar repasse por
muitas camadas. Nesse caso, use o `InheritedWidget` como acesso a dependências,
não como substituto improvisado de um gerenciador de estado.

##### `app_gate.dart`

É o dono da sessão global e dos claims usados para definir o fluxo visual. Em
uma arquitetura com `setState()`, normalmente é um `StatefulWidget` que:

- escuta `authStateChanges()`;
- carrega e valida os claims do ID token;
- mantém o estado de inicialização, sessão e autorização visual;
- mostra splash, login, área do responsável ou área do profissional;
- cancela a assinatura em `dispose()`;
- remove as telas autenticadas da pilha de navegação quando a sessão termina.

##### `theme/`

Contém cores, tipografia, temas e tokens visuais globais. Cores específicas de
uma única feature podem permanecer dentro dela.

#### `lib/core/`

Contém módulos genuinamente compartilhados por features diferentes.

##### `core/errors/`

- exceções estáveis da aplicação;
- resultado de operações;
- conversão de erros de SDK em mensagens e códigos conhecidos;
- nenhuma dependência de widget quando não for necessária.

##### `core/firebase/` ou `core/network/`

- inicialização de SDKs;
- configuração de emuladores;
- criação de clientes compartilhados;
- wrapper técnico comum para invocar Firebase Functions, se mais de uma feature
  realmente precisar dele;
- opções por ambiente.

Não coloque queries, nomes de callables ou payloads de uma feature aqui. Uma
query de perfil pertence ao adapter de repository do perfil; uma Function de
agenda pertence à feature de agenda.

##### `core/widgets/`

Widgets usados por features sem relação entre si, por exemplo:

- loading padrão;
- página de erro padrão;
- botão ou diálogo realmente global.

Um widget usado apenas por duas telas da mesma feature continua em
`features/<feature>/presentation/widgets/`.

##### `core/validators/`, `formatters/` e `extensions/`

Somente regras puras e reutilizadas entre features. Validadores específicos de
cadastro, perfil, animais ou agendamentos ficam dentro da própria feature.

Evite criar arquivos genéricos como `helpers.dart`, `common.dart` ou
`utils.dart`. Prefira nomes que revelem a responsabilidade.

#### `lib/features/<feature>/data/`

É a parte da feature que conhece formatos externos e infraestrutura.

##### `data/models/`

Contém objetos tipados usados pela feature e suas regras de serialização.

Responsabilidades comuns:

- `fromMap`, `fromJson` e `toJson`;
- normalização de dados recebidos;
- tipos de request e response;
- value objects simples;
- enums relacionados à feature.

Não recebe `BuildContext`, não mostra SnackBar e não chama `setState()`.

##### `data/repositories/`

Contém a seam entre a aplicação e a infraestrutura.

Exemplo:

```text
repositories/
├── profile_repository.dart
└── firebase_profile_repository.dart
```

`profile_repository.dart` define operações orientadas ao domínio:

```dart
abstract interface class ProfileRepository {
  Future<UserProfile> loadCurrentProfile();
  Future<void> updateProfile(ProfileUpdate update);
}
```

`firebase_profile_repository.dart` é o adapter que conhece collections,
callables, documentos, códigos de erro e SDKs.

Repositories devem:

- esconder Firebase/HTTP da apresentação;
- devolver models tipados;
- receber clientes por construtor;
- não navegar;
- não mostrar mensagens;
- não guardar `BuildContext`;
- não chamar `setState()`.

##### `data/remote/` e chamadas de Firebase Functions

Não crie um diretório chamado `futures/`. `Future` descreve como uma operação
assíncrona termina, não a responsabilidade do código. Agrupar arquivos pelo
tipo de retorno faz operações de autenticação, perfil e agenda perderem sua
localidade de mudança.

Quando uma feature tiver poucas chamadas simples, mantenha-as diretamente no
adapter de produção:

```text
features/appointments/data/repositories/
├── appointment_repository.dart
└── firebase_appointment_repository.dart
```

O contrato deve usar a linguagem do domínio, mesmo que a implementação chame
uma Firebase Function:

```dart
abstract interface class AppointmentRepository {
  Future<Appointment> schedule(AppointmentRequest request);
  Future<void> cancel(String appointmentId);
}
```

Crie `data/remote/` somente quando houver complexidade suficiente para isolar e
testar — por exemplo, vários callables, montagem de payloads, validação de
respostas e tradução de erros do SDK:

```text
features/appointments/data/
├── remote/
│   └── firebase_appointment_remote.dart
└── repositories/
    ├── appointment_repository.dart
    └── firebase_appointment_repository.dart
```

Nesse caso, o remote adapter conhece nomes de callables e formatos Firebase; o
repository converte esses formatos em models e operações do domínio. Evite
manter as duas camadas se uma apenas repassar todos os argumentos e resultados
da outra sem esconder complexidade real.

Um `core/firebase/firebase_functions_client.dart` pode encapsular somente
comportamento técnico realmente comum, como seleção de região, configuração de
emulador e conversão básica de falhas. Nomes de Functions, payloads e respostas
continuam dentro da feature correspondente.

O fluxo fica:

```text
screen ─► controller ─► repository ─► remote adapter opcional ─► Function
```

A screen nunca deve importar `cloud_functions` nem armazenar a chamada como
uma função global. O `Future` é devolvido pelo contrato e aguardado pelo
controller ou pelo `State`, conforme a complexidade do caso de uso.

#### `lib/features/<feature>/application/`

Contém a coordenação dos casos de uso da feature.

##### `application/controllers/`

Sem Riverpod, controllers são classes Dart comuns. Eles recebem repositories e
expõem operações pequenas que escondem a sequência de trabalho.

```dart
class UpdateProfileController {
  const UpdateProfileController(this._repository);

  final ProfileRepository _repository;

  Future<Result<void>> save(ProfileUpdate update) async {
    try {
      await _repository.updateProfile(update);
      return const Success(null);
    } catch (error, stackTrace) {
      return Failure(mapError(error, stackTrace));
    }
  }
}
```

O controller decide a sequência, valida invariantes de aplicação e traduz
falhas. A tela decide como apresentar loading, erro, navegação e mensagens.

Um controller não deve depender de `State`, `BuildContext`, `Navigator`,
`ScaffoldMessenger` ou `setState()`.

##### `application/states/`

Use quando uma tela ou fluxo possui vários valores relacionados. Em vez de
acumular muitos booleanos soltos, crie um estado imutável:

```dart
enum LoadStatus { initial, loading, success, failure }

class ProfileScreenState {
  const ProfileScreenState({
    this.status = LoadStatus.initial,
    this.profile,
    this.error,
    this.isEditing = false,
  });

  final LoadStatus status;
  final UserProfile? profile;
  final AppException? error;
  final bool isEditing;

  ProfileScreenState copyWith({/* campos */}) {
    // Retorna uma nova instância.
  }
}
```

O `StatefulWidget` continua sendo o dono:

```dart
setState(() {
  _state = _state.copyWith(status: LoadStatus.loading);
});
```

Não é necessário criar um estado separado para uma única flag visual simples.

#### `lib/features/<feature>/presentation/`

Contém tudo o que depende de Flutter e representa a interface.

##### `presentation/screens/`

Screens são páginas completas. Elas:

- possuem controllers de texto, foco, animação e formulário;
- possuem o estado local da página;
- chamam controllers de aplicação;
- transformam resultados em `setState()`, SnackBars, diálogos ou navegação;
- compõem widgets menores;
- tratam `mounted` depois de operações assíncronas;
- descartam recursos em `dispose()`.

Use `guardian` no código para representar o **responsável pelo animal** e
`trainer` para o **treinador**.

Separe telas de responsável e profissional quando o comportamento realmente
for diferente:

```text
screens/
├── guardian/
├── trainer/
└── shared_profile_screen.dart
```

Se a diferença for apenas configuração, prefira duas telas finas chamando uma
implementação compartilhada. Não copie uma tela inteira para trocar um campo.

##### `presentation/widgets/`

Widgets reutilizados dentro da feature. Eles recebem dados e callbacks por
construtor e não acessam infraestrutura diretamente.

Prefira:

```dart
ProfileHeader(
  profile: profile,
  onChangePhoto: _changePhoto,
)
```

Evite um widget que cria seu próprio repository ou busca dados remotos sem que
isso faça parte explícita de sua responsabilidade.

Não crie um diretório `presentation/controllers/` para controllers de negócio.
`TextEditingController`, `AnimationController` e `ScrollController` são objetos
do Flutter mantidos pelo `State`; controllers de casos de uso ficam em
`application/controllers/`.

---

### 6. Fluxo de dependências

As dependências devem apontar nesta direção:

```text
presentation  ─────► application ─────► interfaces de repository
      │                                      ▲
      └────────────► models                  │
                                             │
adapter Firebase/HTTP ───────────────────────┘
```

Regras práticas:

- presentation pode importar application e models da própria feature;
- application pode importar models e interfaces de repository;
- adapters podem importar SDKs e implementar interfaces de repository;
- `core/` não deve importar features;
- uma feature não deve importar detalhes internos de outra;
- contratos realmente compartilhados podem subir para `core/` ou para um
  módulo compartilhado com nome específico;
- widgets nunca importam Firebase diretamente;
- repositories nunca importam widgets.

---

### 7. Padrão de tela assíncrona

```dart
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.controller,
    super.key,
  });

  final ProfileController controller;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  AppException? _error;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await widget.controller.load();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      switch (result) {
        case Success(:final value):
          _profile = value;
        case Failure(:final error):
          _error = error;
      }
    });
  }

  Future<void> _save(ProfileUpdate update) async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    final result = await widget.controller.save(update);
    if (!mounted) return;

    setState(() => _isSaving = false);

    switch (result) {
      case Success():
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado.')),
        );
      case Failure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const AppLoadingIndicator();
    if (_error case final error?) {
      return AppErrorView(message: error.message, onRetry: _load);
    }
    return ProfileContent(profile: _profile!, isSaving: _isSaving);
  }
}
```

Pontos importantes:

- loading, data e error são mutuamente compreensíveis;
- `_isSaving` impede submissão duplicada;
- `mounted` é verificado após cada `await` que antecede uso do widget;
- o controller não conhece Flutter;
- retry chama o mesmo caminho de carregamento;
- a tela apresenta o resultado, mas não implementa a integração.

---

### 8. Estado global sem pacote externo

`setState()` não deve levar à criação de singletons mutáveis.

Para estado global, use um widget raiz que seja o dono explícito:

```text
App
└── AppGate (sessão + claims)
    ├── LoginScreen
    ├── GuardianShell
    │   └── GuardianFeatureScreen
    └── TrainerShell
        └── TrainerFeatureScreen
```

O `AppGate` pode escutar a sessão, carregar os claims e chamar `setState()`.
Telas autenticadas recebem dados e callbacks necessários. Quando a sessão
termina, o gate troca a raiz autenticada pelo login, descarta os claims e limpa
a pilha de navegação que dependia da sessão.

Se muitos descendentes precisam apenas ler dependências estáveis, use um
`InheritedWidget`. Se muitos descendentes precisam editar o mesmo estado
global com alta frequência, reavalie se `setState()` ainda é a ferramenta
adequada para o tamanho do projeto.

---

### 9. Claims, permissões e fluxo de telas

Claims no frontend servem para decidir a experiência: qual shell abrir, quais
telas permitir e quais ações mostrar. Eles **não concedem segurança**. Toda
Firebase Function, regra do Firestore, regra do Storage ou endpoint protegido
deve validar novamente o ID token e as permissões no backend.

#### Modelo e origem dos claims

Leia os claims do ID token emitido pelo Firebase Auth. Não use um campo de
perfil editável no Firestore como fonte de autorização e não permita que o
cliente altere ou fabrique claims.

Modele o resultado de forma tipada e imutável dentro de authentication:

```text
features/authentication/
├── application/
│   ├── controllers/
│   │   └── session_controller.dart
│   └── states/
│       └── session_state.dart
└── data/
    ├── models/
    │   └── user_claims.dart
    └── repositories/
        ├── auth_repository.dart
        └── firebase_auth_repository.dart
```

Exemplo conceitual:

```dart
enum UserType { guardian, trainer }

class UserClaims {
  const UserClaims({
    required this.userType,
    required this.canManageAppointments,
  });

  final UserType userType;
  final bool canManageAppointments;
}
```

O parser deve negar acesso por padrão. Claim ausente, desconhecido, com tipo
incorreto ou incompatível com os demais claims produz sessão sem permissão ou
um erro de autorização controlado; nunca acesso amplo por fallback.

#### Estado da sessão com `setState()`

Prefira um estado explícito a vários booleanos que possam se contradizer:

```dart
sealed class SessionState {
  const SessionState();
}

final class SessionLoading extends SessionState {}
final class SignedOut extends SessionState {}

final class SignedIn extends SessionState {
  const SignedIn({required this.user, required this.claims});

  final AuthUser user;
  final UserClaims claims;
}

final class SessionFailure extends SessionState {
  const SessionFailure(this.error);

  final AppException error;
}
```

O `SessionController` coordena autenticação, leitura do token e parsing. O
`AppGate`, como dono do `SessionState`, aguarda o controller e publica a
mudança com `setState()`. A partir de `SignedIn`, ele escolhe
`GuardianShell` ou `TrainerShell` pelo `UserType`.

Decisões de acesso devem permanecer como funções puras na camada de aplicação,
por exemplo:

```dart
bool canOpenTrainerArea(UserClaims claims) =>
    claims.userType == UserType.trainer;
```

Isso permite testar o fluxo sem `BuildContext` e sem Firebase. As telas podem
ocultar ou desabilitar ações sem permissão para melhorar a experiência, mas
devem lidar também com uma negativa devolvida pelo backend.

#### Atualização e expiração

O ID token pode manter claims antigos até ser renovado. Depois de uma operação
administrativa no backend que altere permissões, force a atualização com o
equivalente a `getIdTokenResult(true)`, recarregue `UserClaims` e só então
recalcule o fluxo de telas. Não grave uma cópia manual dos claims como fonte de
verdade em preferências locais.

Ao receber logout, token inválido ou usuário desabilitado:

1. substitua o estado por uma variante não autenticada ou de erro controlado;
2. descarte os claims em memória;
3. remova as telas autenticadas da pilha de navegação;
4. mostre o login, sem manter uma tela protegida atrás do botão voltar.

---

### 10. Streams e ciclo de vida

Uma stream exige propriedade e descarte explícitos:

```dart
late final StreamSubscription<User?> _subscription;

@override
void initState() {
  super.initState();
  _subscription = widget.authRepository.authStateChanges().listen(
    (user) {
      if (!mounted) return;
      setState(() => _user = user);
    },
    onError: (Object error, StackTrace stackTrace) {
      if (!mounted) return;
      setState(() => _error = mapError(error, stackTrace));
    },
  );
}

@override
void dispose() {
  _subscription.cancel();
  super.dispose();
}
```

Não crie assinaturas em `build()`. Cada rebuild criaria uma nova assinatura.

---

### 11. Formulários

Formulários pertencem à apresentação.

O `State` normalmente possui:

- `GlobalKey<FormState>`;
- `TextEditingController`;
- `FocusNode`;
- seleção temporária;
- modo de edição;
- flags de visibilidade;
- loading de envio.

Regras puras reutilizáveis devem ser funções ou value objects testáveis fora da
árvore de widgets.

Sempre:

- inicialize controllers uma vez;
- descarte-os em `dispose()`;
- faça `trim()` no ponto definido pelo contrato;
- valide antes da operação assíncrona;
- bloqueie submissões duplicadas;
- não registre senhas ou dados pessoais em logs;
- confira `mounted` antes de navegar, mostrar SnackBar ou chamar `setState()`
  depois de um `await`.

---

### 12. Navegação

A navegação é efeito de apresentação. Controllers retornam resultados; telas
decidem navegar.

O HorseLife utiliza `Navigator.push()` para abrir uma nova tela. A tela de
destino é construída diretamente com `MaterialPageRoute`, sem nomes de rotas ou
um arquivo central de rotas:

```dart
await Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (context) => HorseDetailsScreen(horseId: horse.id),
  ),
);
```

Boas práticas:

- chame `Navigator.push()` na camada de apresentação;
- construa a tela de destino diretamente no `builder` de `MaterialPageRoute`;
- passe por construtor apenas os IDs, models e dependências necessários;
- confira `mounted` antes de navegar depois de uma operação assíncrona;
- use `Navigator.pop()` para voltar e, quando necessário, devolver um resultado;
- ao encerrar a sessão, deixe o `AppGate` substituir a árvore autenticada pelo
  login e limpar a pilha de navegação;
- valide os claims tipados antes de abrir telas protegidas, mantendo a
  autorização definitiva no backend;
- ações destrutivas ou amplas exigem confirmação explícita.

---

### 13. Erros

SDKs externos não devem vazar seus erros diretamente para widgets.

Converta-os em uma exceção ou resultado estável:

```dart
class AppException implements Exception {
  const AppException({required this.code, required this.message});

  final String code;
  final String message;
}
```

Separe:

- mensagem segura para a pessoa usuária;
- código técnico estável para lógica e testes;
- detalhe interno permitido para observabilidade;
- dado sensível, que nunca deve ser registrado.

O mesmo erro deve ser convertido em um único mapper, não interpretado de forma
diferente por cada tela.

---

### 14. Testes

#### Models e regras puras

Teste sem Flutter quando possível:

- serialização;
- normalização;
- validação;
- cálculos;
- transições de estado imutável.

#### Controllers de aplicação

Injete repositories fake e teste pela interface pública do controller:

- sucesso;
- falha;
- ordem de operações;
- rollback;
- invariantes.

#### Repositories

- teste o contrato de parsing;
- teste payloads, respostas e mapeamento de erros das Firebase Functions;
- use emulador ou servidor fake para adapters quando o risco justificar;
- não substitua todo teste de integração por mocks que sempre retornam o que o
  código espera.

#### Claims e sessão

- teste o parsing de cada tipo de usuário e permissão;
- teste negação por padrão para claims ausentes, desconhecidos ou malformados;
- teste a escolha entre fluxo de responsável e fluxo de profissional;
- teste logout, token inválido e limpeza das telas autenticadas da pilha de
  navegação;
- teste o recarregamento após a renovação forçada do ID token;
- em integração ou emulador, confirme que o backend também nega operações sem
  permissão, independentemente do que a interface mostra.

#### Widgets e screens

Injete controllers ou repositories fake por construtor e observe resultados
visíveis:

- loading;
- conteúdo;
- erro e retry;
- bloqueio de botão;
- navegação;
- mensagens;
- layouts críticos;
- acessibilidade relevante.

Evite testar campos privados do `State`. O teste deve sobreviver a uma
refatoração interna que preserve o comportamento.

#### Estrutura espelhada

```text
test/
├── app/
├── core/
└── features/
    └── profile/
        ├── application/
        ├── data/
        └── presentation/
```

---

### 15. Regras para criar ou mover arquivos

Antes de criar um arquivo, pergunte:

1. Qual é a responsabilidade dele?
2. Qual feature muda quando ele muda?
3. Ele conhece Flutter?
4. Ele conhece um SDK externo?
5. Ele é reutilizado de verdade ou apenas parece genérico?
6. Existe uma seam real que justifica uma interface?
7. Seu teste natural atravessa qual interface?

Decisão rápida:

| Se o arquivo... | Coloque em... |
|---|---|
| monta a aplicação | `app/` |
| inicializa infraestrutura global | `core/<infraestrutura>/` |
| é widget global real | `core/widgets/` |
| converte dados externos da feature | `features/<feature>/data/models/` |
| implementa o contrato de dados da feature | `features/<feature>/data/repositories/` |
| encapsula vários callables/payloads da feature | `features/<feature>/data/remote/` |
| encapsula transporte Firebase comum, sem regra da feature | `core/firebase/` |
| coordena um caso de uso | `features/<feature>/application/controllers/` |
| representa estado complexo da tela/fluxo | `features/<feature>/application/states/` |
| é uma página completa | `features/<feature>/presentation/screens/` |
| é reutilizado dentro da feature | `features/<feature>/presentation/widgets/` |
| é validação exclusiva da feature | dentro da própria feature |

---

### 16. O que evitar

- Firebase, HTTP ou banco diretamente em widgets.
- `setState()` dentro de repository ou controller de aplicação.
- `BuildContext` guardado em objetos de vida longa.
- uma tela com todas as regras, queries e widgets no mesmo arquivo.
- um controller que apenas repassa cada método do repository sem agregar
  comportamento.
- um repository por método assíncrono.
- um diretório global `futures/` organizado pelo tipo de retorno.
- nomes de Firebase Functions e payloads específicos dentro de `core/`.
- singletons mutáveis usados como estado global.
- estado duplicado em pai e filho.
- múltiplos booleanos incompatíveis, como loading e success verdadeiros ao
  mesmo tempo.
- assinaturas de stream criadas em `build()`.
- `setState()` depois de `dispose()`.
- callbacks assíncronos sem bloqueio contra duplo clique.
- pastas globais de `screens/`, `models/` e `widgets/` que misturam features.
- `utils/` como depósito de arquivos sem responsabilidade clara.
- abstrações criadas apenas para aumentar o número de camadas.
- autorização decidida por campos editáveis do cliente.
- claims persistidos localmente como fonte de verdade.
- acesso liberado como fallback quando um claim estiver ausente ou inválido.
- validação apenas no frontend para regras que precisam ser autoritativas.

---

### 17. Checklist de uma nova feature

- [ ] A feature possui um nome de domínio claro.
- [ ] A maior parte de seus arquivos está dentro de `features/<feature>/`.
- [ ] Dados externos são convertidos em models tipados.
- [ ] A infraestrutura está atrás de um repository quando existe seam real.
- [ ] Firebase Functions estão no adapter da feature ou em `data/remote/` quando
      a complexidade justifica essa camada.
- [ ] Dependencies são injetadas por construtor.
- [ ] O controller não conhece Flutter.
- [ ] O `State` é o dono explícito do estado da tela.
- [ ] `setState()` altera apenas estado de apresentação.
- [ ] Estados assíncronos têm loading, data e error compreensíveis.
- [ ] Operações duplicadas são bloqueadas quando necessário.
- [ ] Recursos são descartados em `dispose()`.
- [ ] Todo uso de contexto após `await` verifica `mounted`.
- [ ] Widgets não acessam Firebase/HTTP diretamente.
- [ ] Navegação acontece na apresentação.
- [ ] Claims tipados controlam o fluxo visual com negação por padrão.
- [ ] Autorização real continua no backend.
- [ ] Mudanças de claims renovam o ID token antes de recalcular o fluxo de
      telas.
- [ ] Testes usam fakes injetados, não dependências globais.
- [ ] Há testes para sucesso, falha e estado visível crítico.
- [ ] A estrutura de testes espelha a estrutura da feature.

---

## Arquitetura do backend — HorseLife

### 1. Objetivo

Este documento define a arquitetura do backend do **HorseLife**, descreve a
responsabilidade de cada pasta e orienta onde adicionar novos arquivos.

Tecnologias consideradas:

- **TypeScript**;
- **Firebase Cloud Functions v2** para disponibilizar os endpoints;
- **Firebase Authentication** para autenticação e identificação dos usuários;
- **MongoDB Atlas** como único banco de dados da aplicação;
- **Cloud Storage** exclusivamente para armazenar imagens, vídeos e arquivos
  PDF.

O backend não utiliza Firebase Firestore. Todos os dados brutos e estruturados,
incluindo as URLs e os metadados dos arquivos enviados ao Cloud Storage, são
persistidos no MongoDB Atlas. O Cloud Storage guarda somente o conteúdo binário
dos arquivos.

### 2. Modelo de arquitetura

O modelo adotado é uma **Arquitetura Modular orientada a Features em Camadas**.

- **Modular:** cada área de negócio fica isolada em seu próprio módulo.
- **Feature-first:** a organização principal representa funcionalidades do
  HorseLife, como autenticação, cavalos, exercícios e treinos.
- **Em camadas:** dentro de cada feature, handlers, services e repositories têm
  responsabilidades diferentes.

O fluxo de uma requisição sem arquivo é:

```text
Aplicativo
    │
    ▼
Handler da Cloud Function
    │
    ▼
Service com a regra de negócio
    │
    ▼
Repository da feature
    │
    ▼
MongoDB Atlas
```

O fluxo de uma operação com imagem, vídeo ou PDF é:

```text
Aplicativo autenticado
    │
    ├── envia o arquivo ──► Cloud Storage
    │                         │
    │                         └── caminho do objeto
    ▼
Handler da Cloud Function
    │
    ▼
Service da feature
    │
    ├── verifica o objeto e obtém a URL ──► Adapter do Cloud Storage
    │
    └── persiste dados brutos, URL e metadados ──► Repository ──► MongoDB Atlas
```

O aplicativo não deve fornecer uma URL arbitrária para persistência. Ele
informa o caminho do objeto enviado; o backend valida a existência, o bucket, o
tipo, o tamanho e a permissão de acesso antes de obter a URL e salvá-la no
MongoDB Atlas.

#### Regras de dependência

1. O `handler` pode chamar um `service`, mas não acessa o MongoDB diretamente.
2. O `service` executa a regra de negócio e usa um `repository` para consultar
   ou persistir dados.
3. O `repository` é o único código da feature que conhece collections, filtros,
   índices e operações do MongoDB.
4. O adapter de Storage é o único componente que conhece bucket, objetos,
   metadados e obtenção de URLs do Cloud Storage.
5. Nenhuma camada lê ou grava dados no Firebase Firestore.
6. Arquivos de uma feature não devem acessar arquivos internos de outra feature.
7. O arquivo `index.ts` define a interface pública de cada módulo.
8. `shared` pode ser usado por todas as features, mas não depende delas.

### 3. Estrutura de pastas

```text
functions/
├── src/
│   ├── index.ts
│   │
│   ├── shared/
│   │   ├── config/
│   │   │   ├── firebase.ts
│   │   │   ├── mongodb.ts
│   │   │   ├── environment.ts
│   │   │   └── functionOptions.ts
│   │   ├── constants/
│   │   │   ├── collections.ts
│   │   │   ├── roles.ts
│   │   │   └── storagePaths.ts
│   │   ├── errors/
│   │   │   ├── AppError.ts
│   │   │   └── mapErrorToHttpsError.ts
│   │   ├── middleware/
│   │   │   ├── requireAuthentication.ts
│   │   │   └── requireRole.ts
│   │   ├── storage/
│   │   │   └── cloudStorage.ts
│   │   ├── types/
│   │   │   ├── authenticatedUser.ts
│   │   │   └── index.ts
│   │   ├── utils/
│   │   │   ├── normalizeText.ts
│   │   │   └── dates.ts
│   │   └── testing/
│   │       ├── database.ts
│   │       └── fixtures.ts
│   │
│   └── features/
│       ├── authentication/
│       │   ├── guardian/
│       │   │   ├── handlers/
│       │   │   ├── services/
│       │   │   ├── repositories/
│       │   │   ├── validations/
│       │   │   ├── types/
│       │   │   └── index.ts
│       │   ├── trainer/
│       │   │   ├── handlers/
│       │   │   ├── services/
│       │   │   ├── repositories/
│       │   │   ├── validations/
│       │   │   ├── types/
│       │   │   └── index.ts
│       │   ├── shared/
│       │   └── index.ts
│       │
│       ├── horses/
│       │   ├── handlers/
│       │   ├── services/
│       │   ├── repositories/
│       │   ├── validations/
│       │   ├── types/
│       │   └── index.ts
│       │
│       ├── exercises/
│       │   ├── handlers/
│       │   ├── services/
│       │   ├── repositories/
│       │   ├── validations/
│       │   ├── types/
│       │   └── index.ts
│       │
│       └── training/
│           ├── handlers/
│           ├── services/
│           ├── repositories/
│           ├── validations/
│           ├── types/
│           └── index.ts
│
├── test/
│   ├── integration/
│   └── e2e/
├── package.json
└── tsconfig.json

storage.rules
firebase.json
```

### 4. O que vai em cada pasta de uma feature

Todas as features seguem a mesma estrutura. O módulo `horses` pode ser
organizado assim:

```text
features/horses/
├── handlers/
│   ├── createHorse.ts
│   ├── getHorse.ts
│   ├── listHorses.ts
│   └── updateHorse.ts
├── services/
│   ├── createHorseService.ts
│   ├── getHorseService.ts
│   ├── listHorsesService.ts
│   └── updateHorseService.ts
├── repositories/
│   └── horseRepository.ts
├── validations/
│   ├── validateCreateHorse.ts
│   └── validateUpdateHorse.ts
├── types/
│   ├── horse.ts
│   ├── horseInputs.ts
│   └── index.ts
└── index.ts
```

#### `handlers/`

Contém os pontos de entrada das Firebase Cloud Functions.

Um handler deve:

1. receber a chamada;
2. verificar a autenticação e a autorização;
3. extrair os dados recebidos;
4. chamar a validação necessária;
5. chamar o service correspondente;
6. devolver a resposta ou converter o erro para `HttpsError`.

O handler deve ser pequeno. Ele não contém regra de negócio nem executa queries
do MongoDB.

Exemplos:

```text
handlers/registerGuardian.ts
handlers/createHorse.ts
handlers/listExercises.ts
handlers/finishTraining.ts
```

#### `services/`

Contém as regras de negócio e a coordenação do fluxo da feature.

Um service pode:

- aplicar regras e permissões específicas;
- coordenar mais de uma operação do repository;
- coordenar a validação de um arquivo no Cloud Storage com a persistência de
  sua URL e de seus metadados no MongoDB;
- verificar a existência de entidades relacionadas;
- preparar os dados que serão persistidos;
- devolver um resultado independente do formato da Cloud Function.

O service não deve criar uma conexão própria com o MongoDB. Ele utiliza as
funções exportadas pelo repository da feature.

#### `repositories/`

Contém todo o acesso ao **MongoDB Atlas** da feature.

Um repository pode:

- obter a collection por meio da conexão compartilhada;
- executar `findOne`, `find`, `insertOne`, `updateOne` e outras operações;
- persistir as URLs e os metadados dos arquivos junto aos dados da feature;
- montar filtros e opções de consulta;
- trabalhar com `ObjectId`;
- controlar projeções, paginação, ordenação e operações atômicas;
- converter documentos do MongoDB para os tipos usados pela aplicação.

Exemplos:

```text
repositories/guardianRepository.ts
repositories/trainerRepository.ts
repositories/horseRepository.ts
repositories/exerciseRepository.ts
repositories/trainingRepository.ts
```

Cada repository deve cuidar somente da collection ou agregado de sua feature. A
URI do Atlas e a criação do `MongoClient` não ficam nos repositories; ficam em
`shared/config/mongodb.ts`.

Repositories não enviam arquivos ao Cloud Storage. Eles recebem do service a
URL e os metadados já validados e persistem essas informações no MongoDB Atlas.

#### `validations/`

Contém a validação e normalização das entradas da feature:

- campos obrigatórios;
- formatos de e-mail, telefone e datas;
- tamanhos mínimos e máximos;
- valores permitidos;
- transformação de strings e identificadores.

Validação de formato fica aqui. Regras como “o profissional pode editar este
treino?” pertencem ao service.

#### `types/`

Contém tipos, interfaces e enums específicos da feature:

- formato da entidade usada pela aplicação;
- formato do documento armazenado no MongoDB;
- payloads de entrada;
- respostas da feature;
- enums específicos.

Tipos de `guardian`, `horse`, `exercise` e `training` não devem ser colocados no
`shared/types` apenas para reduzir imports.

#### `index.ts`

Expõe somente os handlers implantáveis e o que fizer parte da interface pública
do módulo. Implementações internas de services e repositories não devem ser
exportadas sem necessidade.

### 5. Features do HorseLife

#### `features/authentication/guardian/`

Responsável pelo cadastro e pelo perfil do responsável:

- criar o usuário no Firebase Authentication;
- registrar o perfil do responsável no MongoDB Atlas;
- consultar e atualizar o próprio perfil;
- impedir duplicidade dos campos definidos pelo negócio;
- atribuir ou validar a role `guardian`.

Exemplo:

```text
handlers/registerGuardian.ts
services/registerGuardianService.ts
repositories/guardianRepository.ts
validations/validateGuardianRegistration.ts
types/guardian.ts
```

#### `features/authentication/trainer/`

Responsável pelo cadastro e pelo perfil dos profissionais:

- criar o usuário no Firebase Authentication;
- registrar os dados profissionais no MongoDB Atlas;
- armazenar especialidade e registro profissional;
- consultar e atualizar o próprio perfil;
- controlar aprovação cadastral, quando aplicável;
- atribuir ou validar a role `trainer`.

Exemplo:

```text
handlers/registerTrainer.ts
services/registerTrainerService.ts
repositories/trainerRepository.ts
validations/validateTrainerRegistration.ts
types/trainer.ts
```

#### `features/authentication/shared/`

Contém apenas o que é compartilhado entre os módulos `guardian` e
`trainer`, como a criação de credenciais no Firebase Authentication ou um
tipo comum de identidade autenticada.

Esse diretório não substitui o `shared` global. Código usado por outras features
deve ficar em `src/shared/`.

Senhas não são armazenadas no MongoDB. Login, tokens e recuperação de senha são
responsabilidades do Firebase Authentication. O MongoDB armazena o perfil e o
UID do Firebase que relaciona o usuário autenticado aos dados da aplicação.

#### `features/horses/`

Responsável pelo cadastro e pelo ciclo de vida dos cavalos:

- criar e atualizar o perfil do cavalo;
- vincular o cavalo a um responsável;
- autorizar o acesso de profissionais;
- consultar os cavalos permitidos para o usuário autenticado;
- manter informações clínicas, esportivas e de identificação previstas pelo
  produto;
- guardar no MongoDB as URLs e os metadados das imagens e dos PDFs armazenados
  no Cloud Storage.

#### `features/exercises/`

Responsável pelo catálogo de exercícios:

- criar, consultar, atualizar e arquivar exercícios;
- armazenar categoria, objetivo, instruções, nível e duração sugerida;
- definir quem pode cadastrar ou alterar um exercício;
- guardar no MongoDB as URLs e os metadados das mídias demonstrativas
  armazenadas no Cloud Storage.

Um exercício é uma atividade reutilizável. O registro de sua execução para um
cavalo em uma data específica pertence ao módulo de treino.

#### `features/training/`

Responsável pelo planejamento e pelo registro dos treinos:

- criar uma sessão ou um plano de treino;
- associar cavalo, profissional, responsável e exercícios;
- iniciar, concluir ou cancelar uma sessão;
- registrar duração, observações, resultados e evolução;
- consultar o histórico de treinos por cavalo.

Quando precisar de dados de cavalos ou exercícios, o módulo deve utilizar a
interface pública dessas features ou receber os dados já validados. Ele não deve
acessar diretamente os repositories internos de outra feature.

### 6. Pasta global `shared/`

`src/shared/` contém arquivos técnicos realmente utilizados por várias features.
Regras próprias de cavalos, exercícios, treinos ou perfis permanecem em seus
módulos.

#### `shared/config/firebase.ts`

É o único ponto de inicialização do Firebase Admin SDK. Pode exportar:

- a instância do Firebase Admin;
- `auth` para Firebase Authentication;
- `storage` para Cloud Storage.

Nenhuma feature deve inicializar o Firebase novamente.

#### `shared/config/mongodb.ts`

É o único ponto de criação e reutilização da conexão com o **MongoDB Atlas**.
Os repositories importam `getDatabase()` desse arquivo e nunca recebem nem
mantêm uma URI própria. A configuração e o ciclo de vida da conexão estão
detalhados na seção 7.

#### `shared/config/environment.ts`

Lê e valida configurações, como:

- URI do MongoDB Atlas;
- nome do banco;
- nome do bucket;
- parâmetros de integrações externas.

Credenciais e segredos não devem ser enviados ao Git nem armazenados em
`constants/`. Eles devem usar o mecanismo de secrets disponível no ambiente das
Cloud Functions.

#### `shared/config/functionOptions.ts`

Centraliza opções comuns das Cloud Functions, como região, CORS, memória,
timeout e secrets utilizados. Uma configuração excepcional pode permanecer no
handler que a utiliza.

#### `shared/constants/`

Contém valores técnicos estáveis e reutilizados:

- `collections.ts`: nomes das collections do MongoDB;
- `roles.ts`: roles como `guardian`, `trainer` e `admin`;
- `storagePaths.ts`: prefixos de diretórios do Cloud Storage.

Não devem ser colocados aqui segredos, textos de interface ou regras de negócio
que podem mudar.

#### `shared/errors/`

Contém os erros conhecidos do backend e sua conversão para respostas das Cloud
Functions. Services e repositories lançam erros da aplicação; o handler usa
`mapErrorToHttpsError.ts` para produzir a resposta externa adequada.

#### `shared/middleware/`

Contém verificações reutilizáveis executadas pelos handlers:

- exigir um usuário autenticado;
- obter o UID do token;
- validar roles e custom claims;
- recusar uma operação não autorizada.

#### `shared/storage/`

Contém o adapter técnico do Cloud Storage. `cloudStorage.ts` deve:

- validar se o objeto existe no bucket esperado;
- conferir caminho, proprietário, tipo MIME e tamanho;
- obter a URL e os metadados que serão persistidos no MongoDB;
- excluir um objeto quando uma operação precisar ser compensada;
- esconder do restante da aplicação os detalhes do SDK do Storage.

Esse adapter não persiste dados de negócio. O service coordena o adapter de
Storage e o repository da feature.

#### `shared/types/`

Contém somente tipos técnicos usados por várias features, como o contexto do
usuário autenticado. Entidades de negócio permanecem nos `types/` das features.

#### `shared/utils/`

Contém funções puras e genéricas, como normalização de texto e conversão de
datas. Um utilitário só deve ser movido para cá quando for realmente usado por
mais de uma feature.

#### `shared/testing/`

Contém configuração de banco para testes, builders e fixtures genéricas.
Fixtures específicas permanecem próximas da feature correspondente.

### 7. Conexão com o MongoDB Atlas

`shared/config/mongodb.ts` centraliza a conexão com o MongoDB Atlas. Esse
arquivo deve:

- ler a URI do Atlas e o nome do banco por meio de configuração segura;
- criar uma única instância de `MongoClient` por processo;
- reutilizar a conexão entre invocações quentes das Cloud Functions;
- recriar a conexão se a tentativa inicial falhar;
- expor somente uma função como `getDatabase()`;
- registrar falhas sem imprimir a URI, credenciais ou dados sensíveis.

Formato conceitual:

```ts
let clientPromise: Promise<MongoClient> | undefined;

async function getClient(): Promise<MongoClient> {
  if (!clientPromise) {
    const client = new MongoClient(mongoUri);

    clientPromise = client.connect().catch((error) => {
      clientPromise = undefined;
      throw error;
    });
  }

  return clientPromise;
}

export async function getDatabase(): Promise<Db> {
  const client = await getClient();
  return client.db(databaseName);
}
```

A conexão não deve ser aberta novamente em cada handler, service ou repository.
Cada instância ativa da Cloud Function reutiliza seu próprio cliente e o pool de
conexões. O acesso ao cluster deve ser permitido somente para os ambientes da
aplicação, com um usuário de banco que possua as permissões mínimas necessárias.

### 8. Organização dos testes

Testes unitários podem ficar próximos do arquivo testado:

```text
services/createHorseService.ts
services/createHorseService.test.ts
```

Prioridades dos testes unitários:

- regras dos services;
- coordenação entre o adapter de Storage e o repository com fakes;
- validações;
- transformação de dados;
- tratamento de erros conhecidos.

Testes dos repositories devem usar um banco separado para testes e nunca o banco
de produção. Eles ficam em:

```text
functions/test/integration/
```

Testes de fluxos completos entre aplicativo e backend ficam em:

```text
functions/test/e2e/
```

### 9. Ponto de entrada das Cloud Functions

Cada módulo possui um `index.ts` que exporta seus handlers públicos. O arquivo
`src/index.ts` reúne somente as Cloud Functions que serão implantadas.

Exemplo conceitual:

```ts
export {registerGuardian} from "./features/authentication/guardian";
export {registerTrainer} from "./features/authentication/trainer";
export {createHorse, listHorses} from "./features/horses";
export {createExercise, listExercises} from "./features/exercises";
export {createTraining, finishTraining} from "./features/training";
```

Os nomes públicos devem deixar a ação e o contexto explícitos:

```text
registerGuardian
registerTrainer
createHorse
listHorses
createExercise
createTraining
finishTraining
```

Evite exportações genéricas como `create`, `getData` ou `handler`.

### 10. Onde adicionar um arquivo

Use estas perguntas:

1. **Recebe uma chamada ou evento da Cloud Function?** Adicione em `handlers/`.
2. **Executa uma regra ou coordena um fluxo de negócio?** Adicione em
   `services/`.
3. **Consulta ou altera dados no MongoDB?** Adicione em `repositories/`.
4. **Valida um objeto ou obtém sua URL no Cloud Storage?** Use o adapter em
   `shared/storage/`.
5. **Valida ou normaliza um payload?** Adicione em `validations/`.
6. **Define uma entidade, entrada, resposta ou enum?** Adicione em `types/`.
7. **É usado somente por uma feature?** Mantenha dentro dela.
8. **É técnico e utilizado por várias features?** Use a categoria adequada de
   `shared/`.

Exemplo para adicionar “registrar observação em um treino”:

```text
features/training/handlers/addTrainingNote.ts
features/training/services/addTrainingNoteService.ts
features/training/repositories/trainingRepository.ts
features/training/validations/validateTrainingNote.ts
features/training/types/trainingNote.ts
```

### 11. Persistência no MongoDB Atlas

#### Collections sugeridas

```text
guardians
trainers
horses
exercises
trainings
```

Os nomes devem ser centralizados em
`shared/constants/collections.ts`. Subdocumentos podem ser usados quando os dados
sempre forem carregados e alterados com a entidade principal. Dados que crescem
sem limite, precisam de paginação ou são consultados separadamente devem ficar
em collections próprias.

#### Dados e arquivos

O MongoDB Atlas é a fonte de verdade para todos os dados da aplicação. Cada
documento deve armazenar os campos brutos e estruturados da entidade. Quando a
entidade possuir uma imagem, um vídeo ou um PDF, o mesmo documento também deve
armazenar a URL, o caminho do objeto e os metadados necessários do arquivo.

Exemplo conceitual:

```json
{
  "_id": "ObjectId",
  "horseId": "ObjectId",
  "description": "Laudo veterinário",
  "file": {
    "storagePath": "horses/<horseId>/documents/<fileId>.pdf",
    "url": "https://storage.googleapis.com/<bucket>/<object>",
    "contentType": "application/pdf",
    "sizeBytes": 245760,
    "uploadedAt": "2026-10-13T12:00:00.000Z"
  }
}
```

O arquivo binário não deve ser salvo no MongoDB, e os dados da entidade não
devem ser duplicados no Firebase Firestore. O Cloud Storage contém somente o
arquivo; o MongoDB contém os dados e a referência necessária para localizá-lo.

#### Identificadores

- Perfis de usuários devem armazenar o UID do Firebase Authentication.
- Documentos podem usar `_id: ObjectId` como identificador interno.
- Referências entre collections devem manter um tipo consistente.
- Conversões de string para `ObjectId` devem acontecer no repository ou na
  validação de entrada, nunca espalhadas pelos handlers.

#### Índices

Cada repository deve documentar os índices exigidos pelas consultas que executa.
Exemplos:

- índice único para o UID do responsável;
- índice único para o UID do profissional;
- índice para buscar cavalos pelo responsável;
- índice para buscar treinos por cavalo e data;
- índices únicos para campos que não podem ser duplicados.

#### Escritas relacionadas

Quando uma operação alterar vários documentos que precisam permanecer
consistentes, o repository ou service deve utilizar uma sessão e uma transação do
MongoDB. O service determina a regra atômica; o repository executa as operações
de persistência.

Cloud Storage e MongoDB não compartilham uma transação. Se o upload for
concluído e a gravação no MongoDB falhar, o service deve executar uma ação
compensatória, como excluir o objeto enviado. Substituições e exclusões também
devem evitar documentos apontando para arquivos inexistentes e objetos órfãos
no bucket.

### 12. Segurança e dados

- Toda operação protegida deve validar o token do Firebase Authentication.
- A autorização por vínculo ou role deve ocorrer no backend.
- Senhas nunca são armazenadas no MongoDB.
- URLs recebidas do cliente não são persistidas sem a validação do objeto no
  Cloud Storage.
- Uploads devem restringir caminho, tipo MIME e tamanho do arquivo.
- A URI do Atlas e outras credenciais nunca aparecem em logs.
- CPF, registros profissionais, telefones e dados clínicos devem ter acesso
  mínimo e não devem aparecer em mensagens de erro ou logs comuns.
- Acesso ao cluster do Atlas deve ser limitado aos ambientes necessários.
- O usuário do banco deve receber apenas as permissões exigidas pela aplicação.
- Exclusões que precisam preservar histórico devem usar arquivamento ou
  `deletedAt`.
- Datas persistidas devem usar uma convenção única, preferencialmente UTC.

### 13. Convenções

- Pastas e arquivos: `camelCase`.
- Tipos, interfaces e classes: `PascalCase`.
- Funções, variáveis e handlers: `camelCase`.
- Um handler e um fluxo principal por arquivo.
- Handlers terminam com a ação pública: `createHorse.ts`.
- Services usam o sufixo `Service`: `createHorseService.ts`.
- Repositories usam o sufixo `Repository`: `horseRepository.ts`.
- Imports entre features passam pela interface pública do módulo.
- Não criar pastas genéricas como `helpers`, `common` ou `misc`; o nome da pasta
  deve revelar a responsabilidade dos arquivos.
