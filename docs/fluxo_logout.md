# Fluxo de logout

Este documento descreve a callable `logout` e como o frontend deve usá-la. O
encerramento da sessão é gerenciado pelo Firebase Authentication: o backend
apenas revoga os *refresh tokens* do usuário autenticado.

## Ordem do logout

```text
HomeScreen (botão Sair)
  ↓ callable logout (sem corpo), com o ID token no cabeçalho Authorization
onCall verifica o ID token → request.auth.uid
  ↓ requireAuthentication (sem exigir role: guardian e trainer)
  ↓ revokeUserSessions(uid)
Admin SDK auth.revokeRefreshTokens(uid)
  ↓ { mensagem: "Sessão encerrada." }
FirebaseAuth.signOut() no app
  ↓ AppGate observa authStateChanges (usuário nulo)
WelcomeScreen
```

A callable **deve ser chamada antes** do `signOut()` local: depois dele o app
não tem mais ID token e a chamada chegaria como não autenticada.

## Contrato

A callable (região `southamerica-east1`, exige autenticação) não recebe dados.
Qualquer corpo enviado é ignorado:

```json
{}
```

E retorna:

```json
{
  "mensagem": "Sessão encerrada."
}
```

## Segurança da identidade

O UID revogado é sempre `request.auth.uid`, vindo do ID token verificado pelo
próprio `onCall` e entregue por `requireAuthentication`. O handler não lê
`request.data`, então não existe como um cliente pedir a revogação de outro
usuário.

## Responsabilidades

- **Frontend:** chamar `logout`, depois `FirebaseAuth.signOut()`. O `signOut()`
  local deve ocorrer mesmo que a callable falhe (sem rede, por exemplo), para
  que o usuário nunca fique preso na sessão.
- **Backend:** identificar o usuário pelo token e pedir a revogação.
- **Firebase Authentication:** invalidar os refresh tokens e gravar
  `tokensValidAfterTime` no usuário.

## O que a revogação invalida (e o que não invalida)

`revokeRefreshTokens` invalida **refresh tokens**, em **todos os dispositivos**
do usuário. Não invalida ID tokens já emitidos:

| Token | Efeito da revogação |
| --- | --- |
| Refresh token | Inválido imediatamente. O app não consegue renovar a sessão. |
| ID token já emitido | **Continua válido até expirar (até 1 hora).** |
| Custom token de login | Já foi trocado por sessão; não é afetado. |

Isso decorre de como o projeto verifica tokens: o `onCall` do
`firebase-functions` chama `verifyIdToken(idToken)` **sem** `checkRevoked`
(`node_modules/firebase-functions/lib/common/providers/https.js`), e
`requireAuthentication` apenas lê `request.auth`. Consequências:

- Quem obteve um ID token antes do logout (token copiado, dispositivo
  comprometido) ainda consegue chamar as callables por até 1 hora.
- Depois da expiração, o refresh falha e o usuário precisa fazer login de novo.
- No dispositivo que fez logout o efeito é imediato, porque o `signOut()` local
  descarta os tokens.

Impor revogação imediata exigiria `verifyIdToken(token, true)` em toda
requisição, o que adiciona uma consulta ao Firebase Authentication por chamada
e obrigaria `requireAuthentication` (hoje síncrona e usada por todas as
callables) a se tornar assíncrona. Isso não foi feito para não alterar as
demais funcionalidades; os dois mecanismos podem ser adotados depois, se o
risco da janela de 1 hora não for aceitável. Não há sessão paralela própria:
o Firebase Authentication continua sendo a única fonte de verdade.

## Tratamento de falhas

| Situação | Resposta |
| --- | --- |
| Chamada sem token ou com token inválido/expirado | `unauthenticated`, "Faça login para continuar." |
| Token válido de conta já removida do Firebase Authentication | `unauthenticated`, "Faça login para continuar." |
| Falha do Firebase (rede, permissão da service account) | `internal`, "Erro interno." |

Erros inesperados são registrados apenas pelo nome (`mapErrorToHttpsError`),
sem detalhes na resposta.

## Configuração

Nenhuma configuração nova. A service account do Cloud Functions precisa ter,
como já tem para `createUser`/`createCustomToken`, permissão de administração
no Firebase Authentication (papel *Firebase Authentication Admin* ou
equivalente).

## Integração pendente no Flutter

`FirebaseAuthenticationSessionRepository.signOut()` hoje só chama
`FirebaseAuth.instance.signOut()`. O frontend deve, antes disso, chamar
`FirebaseFunctions.instanceFor(region: 'southamerica-east1')
.httpsCallable('logout').call()`, ignorar falhas dessa chamada e prosseguir com
o `signOut()` local. O frontend não foi alterado neste trabalho.
