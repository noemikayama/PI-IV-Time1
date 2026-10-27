# Fluxo de recuperação de senha

Este documento descreve a callable `requestPasswordReset` e como o frontend deve
usá-la. A recuperação é inteiramente gerenciada pelo Firebase Authentication:
o backend apenas solicita o envio, e o link, o e-mail e a redefinição seguem as
configurações do projeto no Console.

## Ordem da recuperação

```text
LoginScreen (onForgotPassword)
  ↓ tela de recuperação: coleta apenas o e-mail
callable requestPasswordReset { email }
  ↓ validatePasswordResetInput (formato do e-mail)
  ↓ sendPasswordReset
Identity Toolkit accounts:sendOobCode { requestType: PASSWORD_RESET, email }
  ↓ Firebase Authentication gera o link e envia o e-mail (template do Console)
{ mensagem } genérica
  ↓ frontend exibe a mensagem
Usuário abre o link do e-mail e redefine a senha na página do Firebase
```

O Admin SDK não envia e-mails: `generatePasswordResetLink` apenas devolve o
link, e enviá-lo exigiria um sistema próprio. Por isso a função usa a REST
`accounts:sendOobCode`, a mesma API do Identity Toolkit que o login já usa
(`signInWithPassword`) com o secret `WEB_API_KEY`.

## Contrato

A callable (região `southamerica-east1`, pública, sem autenticação) recebe:

```json
{
  "email": "usuario@email.com"
}
```

E retorna sempre a mesma resposta quando o e-mail é válido:

```json
{
  "mensagem": "Se houver uma conta associada a este e-mail, enviaremos as instruções para redefinir a senha."
}
```

## Responsabilidades

- **Frontend:** coletar o e-mail, chamar a callable e exibir a mensagem. Não gera
  links, não envia e-mails e não conhece a lógica de recuperação.
- **Backend:** validar o formato, pedir o envio ao Firebase Authentication e
  uniformizar a resposta.
- **Firebase Authentication:** gerar o link, enviar o e-mail e processar a nova
  senha.

## Tratamento de falhas

| Situação | Resposta |
| --- | --- |
| E-mail ausente, não textual, malformado ou com mais de 254 caracteres | `invalid-argument`, "E-mail inválido." |
| Corpo da requisição que não é um objeto | `invalid-argument`, "Dados de cadastro inválidos." |
| E-mail sem conta, conta desativada ou limite de envios atingido | Sucesso com a mensagem genérica |
| Falha de configuração (chave inválida, provedor desativado, cota) ou de rede | `internal`, "Erro interno." |

Todas as recusas que dependem do e-mail informado viram a mesma resposta de
sucesso, para que a função não permita descobrir quais e-mails possuem conta. O
motivo é registrado no log sem o e-mail. Falhas de configuração não dependem do
e-mail e, por isso, podem ser informadas como erro interno.

A existência da conta não é consultada no MongoDB: o Firebase Authentication é a
fonte de verdade das credenciais.

## Integração pendente no Flutter

O `LoginScreen` já expõe o callback `onForgotPassword`, ainda sem fluxo ligado.
O frontend deve, em um repositório injetado como o de login, chamar
`FirebaseFunctions.instanceFor(region: 'southamerica-east1')
.httpsCallable('requestPasswordReset')` com `{ 'email': email }`. Qualquer
resposta de sucesso deve exibir a mensagem genérica; `invalid-argument` indica
e-mail com formato inválido.

## Configuração no Firebase Console

O e-mail enviado depende de configurações que não fazem parte do código:

- **Authentication > Templates > Redefinição de senha:** nome do remetente,
  assunto, mensagem e idioma. Sem alteração, o Firebase usa o template padrão.
- **Authentication > Templates > URL de ação:** por padrão o link abre a página
  hospedada em `<projeto>.firebaseapp.com`. A página própria só é necessária se
  for personalizada.
- **Remetente:** o padrão é `noreply@<projeto>.firebaseapp.com`; um domínio
  próprio exige verificação de DNS.
- **Provedor E-mail/senha** precisa estar ativo, caso contrário a função
  responde `internal`.
