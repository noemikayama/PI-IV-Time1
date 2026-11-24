# Fluxo de cadastro profissional

Este documento descreve a integração do frontend com as Functions existentes
para criar uma conta profissional e enviar seus documentos ao Storage.

## Ordem da operação

```text
RegistrationFlowRoute
  ↓ seleciona o controller profissional
FirebaseTrainerRegistrationRepository
  ↓ registerTrainer (sem PDFs)
Conta criada e UID definido
  ↓ login + signInWithCustomToken
Sessão temporária autenticada
  ↓ createTrainerAttachmentUpload
URL assinada vinculada ao UID
  ↓ PUT do PDF no Storage
  ↓ confirmTrainerAttachment
Documento registrado no perfil
  ↓ signOut
LoginScreen
```

Os PDFs não fazem parte do payload de `registerTrainer`. Eles permanecem
localmente no `TrainerRegistrationDraft` até a conta existir.

## Cadastro sem documentos

A callable `registerTrainer` recebe somente:

```json
{
  "nome": "Ana Silva",
  "email": "ana@email.com",
  "senha": "Senha@123",
  "modalidades": ["Salto"],
  "regioesAtendimento": [
    {"estado": "SP", "cidade": "Campinas"}
  ]
}
```

Seleções que representam um estado inteiro usam `Todas as cidades`. Uma
macrorregião é expandida para suas UFs. Entradas duplicadas são eliminadas e o
limite de 30 regiões do backend é validado antes da chamada.

## Autenticação temporária

As Functions de anexos exigem a role `trainer`. Depois de criar a conta, o
adapter chama `login`, recebe o `customToken` e usa
`FirebaseAuth.signInWithCustomToken`. A sessão existe apenas durante os uploads
e é encerrada ao final.

## Envio dos PDFs

Para cada documento, o frontend:

1. chama `createTrainerAttachmentUpload` com `experiencias` ou
   `certificacoes`;
2. recebe `caminho`, `uploadUrl` e os headers obrigatórios;
3. envia os bytes por `PUT` diretamente ao Storage;
4. chama `confirmTrainerAttachment` com o tipo e o caminho.

O documento de experiência é enviado antes das certificações. As certificações
são processadas sequencialmente porque o backend escolhe o próximo índice livre
depois de cada confirmação.

Os headers recebidos devem ser enviados no `PUT` exatamente como vieram. A URL
de uma certificação só aceita o envio se o caminho estiver livre: um segundo
`PUT` para o mesmo caminho recebe `412` do Storage. A experiência tem caminho
fixo, e um novo envio substitui o anterior.

O frontend aplica os mesmos limites do backend: PDF de até 10 MB, uma
experiência e no máximo dez certificações.

## Falhas parciais

Se uma falha ocorrer antes de `registerTrainer`, a revisão permanece aberta e
permite nova tentativa. Se ocorrer depois, a conta já existe; o fluxo segue para
o login e apresenta um aviso, evitando tentar cadastrar novamente o mesmo
e-mail.

## Arquivos principais

| Responsabilidade | Arquivo |
| --- | --- |
| Composição por perfil | `horse_life/lib/features/authentication/presentation/routes/registration_flow_route.dart` |
| Integração do cadastro e dos PDFs | `horse_life/lib/features/authentication/data/repositories/firebase_trainer_registration_repository.dart` |
| Modalidades remotas | `horse_life/lib/features/authentication/data/repositories/firebase_training_sport_repository.dart` |
| Dados locais dos PDFs | `horse_life/lib/features/authentication/application/states/trainer_document.dart` |
| Confirmação e feedback | `horse_life/lib/features/authentication/presentation/screens/trainer_confirmation_screen.dart` |
