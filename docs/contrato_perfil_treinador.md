# Contrato da edição do perfil do treinador

Callables na região `southamerica-east1`. Todas exigem login de **treinador**;
o perfil editado é sempre o do token (`request.auth.uid`), nunca um ID enviado
pelo app.

## Visão geral da tela "Editar perfil"

| Ação na tela | Callable |
| --- | --- |
| Carregar os dados | `getTrainerProfile` |
| Primeiro nome, sobrenome, regiões, remover PDF | `updateTrainerProfile` |
| Adicionar PDF de experiência ou certificação | `createTrainerAttachmentUpload` + envio + `confirmTrainerAttachment` |
| Alterar senha | `requestPasswordReset` com o e-mail do treinador |

Ao tocar em **Salvar alterações**, chame nesta ordem:

1. `updateTrainerProfile` com o nome, as regiões e os PDFs removidos;
2. o envio de cada PDF novo (mesmo fluxo do cadastro, ver
   [fluxo_cadastro_profissional.md](fluxo_cadastro_profissional.md)).

A ordem importa: aguarde a resposta de `updateTrainerProfile` antes de pedir
qualquer envio. O PDF removido é apagado do Storage pouco antes dessa resposta,
e o caminho liberado pode ser reaproveitado pelo próximo envio (a experiência usa
sempre `experiencia_1.pdf`; a certificação usa o menor índice livre). Para
**substituir** a experiência, basta enviar o novo PDF, sem pedir a remoção.

Se `updateTrainerProfile` retornar erro, **não reenvie o mesmo pedido**:
recarregue com `getTrainerProfile`. As alterações são diferenças
(`adicionar`/`remover`) e podem já ter sido gravadas (por exemplo, se a
conexão caiu depois da gravação); repeti-las retorna `not-found` ou
`invalid-argument`.

## updateTrainerProfile

Envie apenas o que mudou: campo ausente não é alterado. Qualquer campo fora da
tabela (`email`, `senha`, `modalidades`, `uid`...) é recusado.

```json
{
  "nome": "Ana",
  "sobrenome": "Souza",
  "regioesAtendimento": {
    "adicionar": [{ "estado": "MG", "cidade": "Uberaba" }],
    "remover": [{ "estado": "SP", "cidade": "Ribeirão Preto" }]
  },
  "experiencias": { "remover": "/arquivos/treinadores/<uid>/experiencia_1.pdf" },
  "certificacoes": { "remover": ["/arquivos/treinadores/<uid>/certificacao_1.pdf"] }
}
```

| Campo | Regra |
| --- | --- |
| `nome`, `sobrenome` | Enviados juntos e gravados como `"<nome> <sobrenome>"` (3 a 120 caracteres). Nome igual ao atual não é alteração. |
| `regioesAtendimento.adicionar` | Mesmo formato do cadastro (`estado` com 2 letras maiúsculas, `cidade`, `complemento` opcional). Região já cadastrada ou repetida na lista retorna `invalid-argument`. |
| `regioesAtendimento.remover` | Região como devolvida por `getTrainerProfile`. Região inexistente retorna `not-found`. As demais regiões são mantidas. |
| `experiencias.remover` | `caminho` atual da experiência. |
| `certificacoes.remover` | `caminho` de cada certificação a remover. As demais são mantidas. |

- A comparação de regiões não diferencia maiúsculas; o total após a edição é
  de até 30 regiões.
- Anexo inexistente retorna `not-found`; caminho de outro usuário retorna
  `invalid-argument`.
- Tudo é gravado em uma única transação: se uma regra falhar, nada é alterado.
  O PDF removido só é apagado do Storage depois da gravação.
- O novo nome também é atualizado no Firebase Authentication, em
  `cavalos.treinadores`, `cavalos.avaliacoes.treinador` e
  `registros_treino.treinador`.

Resposta (mesmo formato de `getTrainerProfile`):

```json
{
  "nome": "Ana Souza",
  "experiencias": null,
  "certificacoes": [{ "caminho": "/arquivos/treinadores/<uid>/certificacao_2.pdf", "url": "https://..." }],
  "regioesAtendimento": [{ "estado": "SP", "cidade": "Campinas" }, { "estado": "MG", "cidade": "Uberaba" }],
  "atualizadoEm": "2026-10-29T18:00:00.000Z"
}
```

## Alterar senha

O botão não usa `updateTrainerProfile`. Chame `requestPasswordReset` com
`{ "email": "<e-mail do perfil>" }` (ver
[fluxo_recuperacao_senha.md](fluxo_recuperacao_senha.md)).

## Arquivos principais

- `functions/src/features/authentication/trainer/handlers/updateTrainerProfile.ts`
- `functions/src/features/authentication/trainer/services/updateTrainerProfileService.ts`
- `functions/src/features/authentication/trainer/validations/validateTrainerProfile.ts`
- `functions/src/features/authentication/trainer/repositories/trainerRepository.ts`
