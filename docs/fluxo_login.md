# Fluxo de login

Este documento descreve a integração do frontend com a callable `login` e com
o Firebase Authentication. O backend existente não foi alterado.

## Ordem da autenticação

```text
WelcomeScreen
  ↓ LoginFlowRoute
LoginScreen
  ↓ LoginController
FirebaseLoginRepository
  ↓ callable login { email, senha }
customToken + role + nome
  ↓ FirebaseAuth.signInWithCustomToken
ID token autenticado
  ↓ validação do claim role
LoginSession { uid, name, role }
  ↓ AppGate observa authStateChanges
HomeScreen
```

O `LoginFlowRoute` concentra a criação do controller e do repositório. Dessa
forma, a tela não cria dependências do Firebase e continua testável com uma
operação de login injetada.

## Contrato utilizado

A callable recebe:

```json
{
  "email": "usuario@email.com",
  "senha": "Senha@123"
}
```

E retorna:

```json
{
  "customToken": "...",
  "role": "guardian",
  "nome": "Ana Silva"
}
```

O token customizado é trocado por uma sessão real do Firebase. Depois da
autenticação, o frontend força a leitura do ID token e compara seu claim `role`
com o papel informado pela callable. Uma divergência encerra a sessão e impede
que o resultado seja aceito.

O aplicativo reconhece exclusivamente os papéis `guardian` e `trainer`.
Qualquer outro valor é tratado como resposta inválida e não cria uma sessão.

## Persistência e navegação

O resultado é representado por `LoginSession`, contendo UID, nome e papel. A
rota de login é fechada após o sucesso e o `AppGate` observa as mudanças do
Firebase Authentication, sem depender de callbacks para propagar a sessão.
Como o SDK preserva a autenticação, ao reiniciar o app o gate restaura UID,
nome e role a partir do usuário e do ID token, abrindo a home sem solicitar
novamente as credenciais.

Enquanto as áreas definitivas dos perfis não estão presentes nesta branch, a
home contém apenas o botão `Sair`. Ele chama `FirebaseAuth.signOut`; a emissão
da sessão nula faz o gate voltar para a tela de boas-vindas.

## Tratamento de falhas

- credenciais recusadas são apresentadas como e-mail ou senha incorretos;
- conta inativa, desativada ou temporariamente bloqueada preserva a mensagem
  segura enviada pelo backend;
- respostas incompletas ou claims divergentes são rejeitados;
- timeout e falhas inesperadas são apresentados como erro de conexão;
- senhas nunca são armazenadas na sessão ou no estado de domínio.
