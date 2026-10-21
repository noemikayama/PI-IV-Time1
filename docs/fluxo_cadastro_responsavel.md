# Fluxo de cadastro do responsável

Este documento descreve o caminho percorrido pelo frontend desde o início do
cadastro de um responsável até a chamada da Firebase Callable Function
`registerGuardian`.

## Visão geral

```text
main.dart
  ↓ injeta Controller + Repository
WelcomeScreen
  ↓ repassa o controller
ProfileSelectionScreen
  ↓ Responsável
RegistrationNameScreen
  ↓ nome
RegistrationEmailScreen
  ↓ e-mail
RegistrationPasswordScreen
  ↓ senha
GuardianConfirmationScreen
  ↓ botão "Criar conta"
RegistrationController
  ↓
FirebaseGuardianRegistrationRepository
  ↓
FirebaseFunctions.httpsCallable("registerGuardian").call(...)
```

A referência à callable é indireta. O nome `registerGuardian` fica armazenado
em uma constante e depois é passado para `httpsCallable(_functionName)`. Por
isso, uma busca por `httpsCallable('registerGuardian')` não encontra a chamada.

## 1. Criação e injeção das dependências

O ponto inicial está em `horse_life/lib/main.dart`:

```dart
home: const WelcomeScreen(
  registrationController: RegistrationController(
    FirebaseGuardianRegistrationRepository(),
  ),
),
```

Nesse ponto são criados:

- `FirebaseGuardianRegistrationRepository`, que conhece o Firebase;
- `RegistrationController`, que conecta as telas ao repositório;
- `WelcomeScreen`, que recebe o controller e inicia o fluxo visual.

A criação do repositório não chama o Firebase imediatamente. A chamada remota
só acontece na confirmação final do cadastro, depois que o `AppGate` conclui a
inicialização do Firebase.

## 2. Propagação do controller pelas telas

O mesmo `registrationController` é repassado entre as telas:

1. `welcome_screen.dart` abre a seleção de perfil;
2. `profile_selection_screen.dart` abre o cadastro de responsável;
3. `registration_name_screen.dart` coleta nome e sobrenome;
4. `registration_email_screen.dart` adiciona o e-mail;
5. `registration_password_screen.dart` mantém a senha temporariamente e abre a
   confirmação;
6. `guardian_confirmation_screen.dart` realiza o envio.

As informações não sensíveis são transportadas por um
`GuardianRegistrationDraft`. A senha é passada separadamente para não ser
armazenada no draft ou em armazenamento local.

## 3. Clique em "Criar conta"

Em `guardian_confirmation_screen.dart`, o botão final executa o método
`_createAccount`:

```dart
onPressed: _createAccount,
```

O método valida o formulário, impede envios duplicados e chama o controller:

```dart
await controller.createAccount(
  registration: widget.registration.copyWithContact(
    firstName: _firstNameController.text.trim(),
    lastName: _lastNameController.text.trim(),
    email: _emailController.text.trim(),
  ),
  password: _passwordController.text,
);
```

## 4. Passagem pelo controller

O `RegistrationController` não conhece Firebase e não serializa os dados. Ele
somente encaminha a operação ao repositório configurado em `main.dart`:

```dart
Future<void> createAccount({
  required RegistrationDraft registration,
  required String password,
}) {
  return _repository.createAccount(
    registration: registration,
    password: password,
  );
}
```

Esse código está em:

```text
horse_life/lib/features/authentication/application/controllers/
  registration_controller.dart
```

## 5. Montagem do payload

O `FirebaseGuardianRegistrationRepository` converte o draft para o contrato
esperado pelo backend:

```dart
final data = <String, Object>{
  'nome':
      '${registration.firstName.trim()} '
      '${registration.lastName.trim()}',
  'email': registration.email.trim(),
  'senha': password,
};
```

O objeto enviado possui este formato:

```json
{
  "nome": "Ana Silva",
  "email": "ana@email.com",
  "senha": "Senha@123"
}
```

## 6. Chamada da callable

O nome e a região da Function ficam declarados em
`firebase_guardian_registration_repository.dart`:

```dart
static const _region = 'southamerica-east1';
static const _functionName = 'registerGuardian';
```

A chamada propriamente dita é:

```dart
await FirebaseFunctions.instanceFor(
  region: _region,
).httpsCallable(_functionName).call<void>(data);
```

Esse código equivale conceitualmente a:

```dart
FirebaseFunctions
    .instanceFor(region: 'southamerica-east1')
    .httpsCallable('registerGuardian')
    .call(data);
```

O arquivo central da integração é:

```text
horse_life/lib/features/authentication/data/repositories/
  firebase_guardian_registration_repository.dart
```

## 7. Operação no backend

A callable pública `registerGuardian` recebe o objeto enviado pelo frontend. O
backend:

1. valida e normaliza `nome`, `email` e `senha`;
2. cria o usuário no Firebase Authentication;
3. atribui a função de responsável ao usuário;
4. cria o perfil do responsável no MongoDB;
5. reserva o e-mail;
6. devolve `id`, `codigo` e `email`.

Os arquivos do backend relacionados são:

```text
functions/src/features/authentication/guardian/handlers/registerGuardian.ts
functions/src/features/authentication/guardian/services/registerGuardianService.ts
functions/src/features/authentication/guardian/validations/
  validateGuardianRegistration.ts
```

O frontend aguarda a conclusão da chamada, mas não precisa consumir os campos
do resultado para finalizar o fluxo.

## 8. Retorno da operação

Quando o cadastro é concluído:

1. a senha mantida na tela é apagada;
2. o fluxo de cadastro é removido da pilha de navegação;
3. o usuário é direcionado para `LoginScreen`.

Quando ocorre uma falha conhecida:

- `already-exists`: apresenta **E-mail já cadastrado.**;
- `invalid-argument`: apresenta a mensagem de validação enviada pelo backend;
- outros erros: apresenta **Erro de conexão com o servidor**.

Os detalhes internos inesperados do Firebase ou do backend não são exibidos
na interface.

## Arquivos principais

| Responsabilidade | Arquivo |
| --- | --- |
| Montagem das dependências | `horse_life/lib/main.dart` |
| Estado do cadastro | `horse_life/lib/features/authentication/application/states/registration_draft.dart` |
| Coordenação da submissão | `horse_life/lib/features/authentication/application/controllers/registration_controller.dart` |
| Contrato do repositório | `horse_life/lib/features/authentication/data/repositories/registration_repository.dart` |
| Integração com a callable | `horse_life/lib/features/authentication/data/repositories/firebase_guardian_registration_repository.dart` |
| Confirmação e envio | `horse_life/lib/features/authentication/presentation/screens/guardian_confirmation_screen.dart` |

