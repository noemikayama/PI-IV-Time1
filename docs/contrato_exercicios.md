# Contrato das callables de exercícios

Callables na região `southamerica-east1`. `_id` sempre como string
hexadecimal. Todas exigem login de **treinador**, exceto
[getExercise](#getexercise), que também atende o **responsável**; com outro
perfil, retornam `permission-denied`.

A galeria de exercícios (`listExerciseGallery`) e o tempo total da seleção
(`sumExerciseDurations`), usados no cadastro de treinamentos, estão em
[contrato_treinamentos.md](contrato_treinamentos.md). Os detalhes e a edição
de um exercício estão em [getExercise](#getexercise) e
[updateExercise](#updateexercise).

## Fluxo da tela de cadastro

1. O treinador escolhe o tipo: **genérico** (`GENERICO`) ou **específico**
   (`ESPECIFICO`). O campo de cavalo só aparece no específico.
2. O app chama `registerExercise` com os dados do formulário e recebe o `id`
   do exercício.
3. Para cada foto ou vídeo anexado, o app segue o fluxo de [Mídias](#mídias)
   com esse `id`, **um arquivo de cada vez**.

O exercício já existe depois do passo 2. Se o envio de uma mídia falhar, o
exercício continua cadastrado: mostre o erro daquele arquivo e permita tentar
de novo ou removê-lo.

### Cavalos disponíveis para seleção

São os cavalos vinculados ao treinador, na lista `cavalos` de
`getTrainerProfile`:

```json
"cavalos": [
  { "_id": "66e1a0c2f1b2c3d4e5f60050", "codigo": "123123456789012", "nome": "Trovão" }
]
```

Envie o `_id` escolhido como `cavaloId`. Não use a lista de `getHome`: ela
traz só os 5 primeiros. O backend confere o vínculo de novo no cadastro, então
um cavalo fora dessa lista é recusado.

## registerExercise

```json
{
  "privacidade": "ESPECIFICO",
  "cavaloId": "66e1a0c2f1b2c3d4e5f60050",
  "nome": "Transições trote-galope",
  "descricao": "Alternar trote e galope em intervalos definidos.",
  "orientacoes": ["Manter contato leve com as rédeas", "Repetir em ambas as mãos"],
  "duracaoPadraoMinutos": 20,
  "materiais": [
    { "descricao": "Cavalete", "quantidade": 2 },
    { "descricao": "Vara", "quantidade": 3 }
  ]
}
```

No exercício genérico, envie `"privacidade": "GENERICO"` e omita `cavaloId`
(ou envie `null`).

| Campo | Regra |
| --- | --- |
| `privacidade` | `GENERICO` ou `ESPECIFICO`, sem acento. |
| `cavaloId` | Obrigatório no `ESPECIFICO`; proibido no `GENERICO`. Precisa ser um cavalo ativo vinculado ao treinador. |
| `nome` | 3 a 80 caracteres. |
| `descricao` | 1 a 1000 caracteres. |
| `orientacoes` | Opcional. Até 30 itens, cada um com 1 a 500 caracteres, sem item vazio. |
| `duracaoPadraoMinutos` | Inteiro de 1 a 240. |
| `materiais` | Opcional (lista vazia é aceita). Até 30 itens. `descricao` com 1 a 100 caracteres e `quantidade` inteira de 1 a 999. O mesmo material não pode aparecer duas vezes (sem diferenciar maiúsculas): some as quantidades. |

Os textos têm os espaços das pontas removidos antes da validação.

Resposta: `{ "id": "...", "codigo": 23, "nome": "Transições trote-galope" }`.

O exercício é criado com `imagens: []` e `videos: []`.

| Erro | Quando |
| --- | --- |
| `invalid-argument` | Algum campo fora das regras acima. A mensagem diz qual. |
| `permission-denied` | Treinador com situação profissional diferente de `DISPONIVEL`, ou cavalo sem vínculo com o treinador. |
| `not-found` | O cavalo não existe ou foi excluído. |

## Mídias

Só o treinador que cadastrou o exercício pode enviar e remover mídias
(`permission-denied` para os demais). O fluxo é o mesmo das imagens do cavalo:
o app envia os bytes direto ao Storage por uma URL assinada.

Para cada arquivo, o app:

1. chama `createExerciseMediaUpload` com `id` e `contentType`;
2. recebe `caminho`, `uploadUrl` e os headers obrigatórios;
3. envia os bytes por `PUT` para `uploadUrl`, com esses headers, em até 10
   minutos;
4. chama `confirmExerciseMedia` com `id` e `caminho`.

Envie os headers exatamente como recebidos. A URL só aceita o envio se ainda
não houver arquivo no caminho: um segundo `PUT` para o mesmo caminho é recusado
pelo Storage com `412`. Para trocar uma mídia, remova-a e peça uma nova URL.

Prefira enviar um arquivo de cada vez. O backend escolhe o menor índice livre
e pula os caminhos de envios feitos e ainda não confirmados. Se dois pedidos
simultâneos receberem o mesmo caminho, o segundo `PUT` recebe `412`: peça
outra URL e reenvie. Um envio não confirmado em 30 minutos é considerado
abandonado e o caminho volta a ficar livre.

| Regra | Fotos | Vídeos |
| --- | --- | --- |
| Formatos | `image/jpeg` ou `image/png` | `video/mp4` |
| Tamanho | Até 5 MB | Até 50 MB |
| Quantidade | Até 10 por exercício | Até 3 por exercício |
| Duração | — | Até 30 segundos |
| Caminho | `/fotos/exercicios/<codigo>_<n>.jpg` (ou `.png`) | `/videos/exercicios/<codigo>_<n>.mp4` |

O conteúdo é conferido no backend: o formato pelos primeiros bytes e a duração
do vídeo pelo próprio arquivo. Recomenda-se recusar no app, antes do envio,
vídeos com mais de 30 s (pela duração informada pelo player) e arquivos acima
do tamanho máximo, para não gastar o envio.

**Vídeos do iPhone:** a câmera do iOS grava em `.mov` (QuickTime), que não é
aceito, nem mesmo enviado como `video/mp4`: o backend identifica o `.mov` pelo
conteúdo e o recusa. O app deve converter o vídeo para MP4 com H.264 antes do
envio (por exemplo, com `video_compress`), o que também ajuda a ficar abaixo
de 50 MB e garante que o vídeo toque no Android.

### createExerciseMediaUpload

```json
{ "id": "66e1a0c2f1b2c3d4e5f6c010", "contentType": "video/mp4" }
```

Resposta:

```json
{
  "caminho": "/videos/exercicios/23_1.mp4",
  "uploadUrl": "https://storage.googleapis.com/...",
  "headers": {
    "Content-Type": "video/mp4",
    "x-goog-content-length-range": "0,52428800",
    "x-goog-if-generation-match": "0"
  }
}
```

Com o limite de fotos ou de vídeos atingido, retorna `invalid-argument`. Se
todos os índices livres estiverem ocupados por envios ainda não confirmados,
retorna `failed-precondition`.

### confirmExerciseMedia

```json
{ "id": "66e1a0c2f1b2c3d4e5f6c010", "caminho": "/videos/exercicios/23_1.mp4" }
```

Resposta: `{ "caminho": "...", "url": "..." }`. A `url` é assinada e vale 15
minutos; o `caminho` identifica a mídia para removê-la.

Retorna `not-found` se o arquivo não foi enviado. Se o arquivo não tiver o
formato, o tamanho ou a duração aceitos, ele é apagado e a resposta é
`invalid-argument`, com o motivo na mensagem.

### removeExerciseMedia

Mesmo corpo de `confirmExerciseMedia`. Apaga a mídia do exercício e do Storage
e responde `{ "removido": true }`, ou `not-found` se ela não estiver no
exercício.

## getExercise

Tela de detalhes do exercício, a mesma para o **treinador** e o
**responsável**. Envie o `id` **ou** o `codigo` do exercício, só um dos
dois:

```json
{ "id": "66e1a0c2f1b2c3d4e5f6c010" }
```

```json
{ "codigo": "23" }
```

| Campo | Regra |
| --- | --- |
| `id` | `_id` do exercício, como vem do cadastro, da galeria e das mídias. |
| `codigo` | Código do exercício, como string só com dígitos ou como inteiro. É o que a tela "Detalhes do treino" (`getTrainingDetails`) traz em `exercicios[].codigo`. |

Outros campos são recusados.

Quem recebe o exercício:

- o **treinador que o cadastrou**, sempre;
- quem tem vínculo hoje (proprietário, atleta ou treinador) com o cavalo de
  um exercício **específico**;
- quem tem vínculo hoje com um cavalo cujo **plano** (de qualquer situação)
  ou **registro de treino** usa o exercício, genérico ou específico.

Nos outros casos a resposta é `not-found`, como se o exercício não
existisse. Os dados são os do exercício **como está hoje**, e não a cópia
guardada no treinamento, no plano ou no registro.

Resposta:

```json
{
  "id": "66e1a0c2f1b2c3d4e5f6c010",
  "codigo": 23,
  "nome": "Transições trote-galope",
  "descricao": "Alternar trote e galope em intervalos definidos.",
  "orientacoes": ["Manter contato leve com as rédeas"],
  "duracaoPadraoMinutos": 20,
  "materiais": [{ "descricao": "Cavalete", "quantidade": 2 }],
  "privacidade": "ESPECIFICO",
  "cavalo": { "id": "66e1a0c2f1b2c3d4e5f60050", "codigo": "123123456789012", "nome": "Trovão" },
  "treinador": { "id": "<uid>", "codigo": 92, "nome": "Carlos Mendes" },
  "imagens": [{ "caminho": "/fotos/exercicios/23_1.jpg", "url": "https://storage.googleapis.com/..." }],
  "videos": [],
  "permissoes": { "editar": true },
  "criadoEm": "2026-11-10T14:30:00.000Z",
  "atualizadoEm": "2026-11-20T09:12:00.000Z"
}
```

| Campo | Observação |
| --- | --- |
| `cavalo` | Só no `ESPECIFICO`, e só para o autor ou para quem tem vínculo com esse cavalo (`codigo` é o microchip). Se o exercício mudou de cavalo depois de entrar no plano de outro cavalo, quem só tem vínculo com o cavalo do plano recebe o exercício sem `cavalo`. |
| `treinador` | Quem cadastrou o exercício. |
| `imagens`, `videos` | Na ordem em que foram anexados, com `caminho` e `url`. A `url` é assinada e vale 15 minutos: se a tela ficar aberta mais que isso, chame `getExercise` de novo. Listas vazias quando não há mídia. |
| `permissoes.editar` | `true` só para quem cadastrou o exercício. Mostre "Editar" e os botões de mídia só nesse caso. |
| `criadoEm`, `atualizadoEm` | ISO 8601 (UTC). `atualizadoEm` também muda quando uma mídia é incluída ou removida. Para avisar que o exercício mudou depois do planejamento, compare com a data do plano. |

| Erro | Quando |
| --- | --- |
| `unauthenticated` | Sem login. |
| `permission-denied` | Conta inativa ou inexistente, ou perfil que não é treinador nem responsável. |
| `invalid-argument` | Sem `id` e sem `codigo`, os dois juntos, um deles fora do formato, ou campo desconhecido. |
| `not-found` | O exercício não existe, foi excluído ou o usuário não tem acesso a ele. |

## updateExercise

Salva a tela de edição. Só o **treinador que cadastrou** o exercício edita,
em qualquer situação profissional, menos `INATIVO`.

Envie o `id` e só os campos que mudaram (mandar o formulário inteiro também
funciona):

```json
{
  "id": "66e1a0c2f1b2c3d4e5f6c010",
  "nome": "Transições curtas trote-galope",
  "orientacoes": [],
  "privacidade": "ESPECIFICO",
  "cavaloId": "66e1a0c2f1b2c3d4e5f60051"
}
```

| Campo | Regra |
| --- | --- |
| `id` | Obrigatório. |
| `nome`, `descricao`, `orientacoes`, `duracaoPadraoMinutos`, `materiais` | Opcionais, com as mesmas regras de [registerExercise](#registerexercise). Campo ausente não muda; `[]` ou `null` em `orientacoes` e `materiais` esvazia a lista. |
| `privacidade` | Opcional. `GENERICO` tira o cavalo; `ESPECIFICO` exige `cavaloId`. |
| `cavaloId` | Só junto com `privacidade`, e proibido no `GENERICO`; `null` sem `privacidade` é ignorado. Se for o cavalo atual, ele é mantido sem conferir o vínculo de novo. Se for outro, precisa ser um cavalo ativo vinculado ao treinador (a lista `cavalos` de `getTrainerProfile`). |

Outros campos são recusados, inclusive `codigo`, `imagens`, `videos`,
`treinador` e as datas. Fotos e vídeos continuam pelo fluxo de
[Mídias](#mídias). Um pedido sem nenhum campo além do `id` também é recusado.

| Exercício hoje | Pedido | Resultado |
| --- | --- | --- |
| Qualquer | sem `privacidade` | Tipo e cavalo não mudam. |
| Genérico | `ESPECIFICO` + cavalo H | Específico de H, se H estiver ativo e vinculado ao treinador. |
| Específico de H | `ESPECIFICO` + H | Continua de H, mesmo que o vínculo tenha acabado. |
| Específico de H | `ESPECIFICO` + H2 | Específico de H2, se H2 estiver ativo e vinculado ao treinador. |
| Específico de H | `GENERICO` | Genérico, sem cavalo. |

O que a edição não muda:

- as cópias do exercício em treinamentos, planos e registros de treino: a
  edição vale para os treinamentos montados depois;
- os planos já criados, mesmo quando o tipo ou o cavalo mudam. A galeria de
  treinamentos do plano (`listTrainingGallery`) passa a considerar o tipo e
  o cavalo novos só nos planos criados depois.

Resposta: o exercício atualizado, no formato de [getExercise](#getexercise),
com `permissoes.editar: true`.

| Erro | Quando |
| --- | --- |
| `unauthenticated` | Sem login. |
| `permission-denied` | Perfil diferente de treinador; conta inativa; treinador que pode ver o exercício, mas não o cadastrou; cavalo novo sem vínculo com o treinador. |
| `invalid-argument` | Campo fora das regras (a mensagem diz qual), campo desconhecido, `cavaloId` sem `privacidade`, ou nenhuma alteração. |
| `not-found` | O exercício não existe, foi excluído ou o treinador não tem acesso a ele; ou o cavalo novo não existe ou foi excluído. |

### Fluxo da tela de edição

1. A tela abre com `getExercise` e preenche o formulário com a resposta.
2. "Salvar" chama `updateExercise` com os campos alterados e mostra a
   resposta.
3. Fotos e vídeos são incluídos e removidos pelas callables de
   [Mídias](#mídias), um arquivo de cada vez, como no cadastro.
4. Depois de mexer nas mídias, ou se a tela ficar aberta mais de 15 minutos,
   chame `getExercise` de novo para ter as URLs atualizadas.
