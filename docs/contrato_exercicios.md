# Contrato das callables de exercícios

Callables na região `southamerica-east1`. `_id` sempre como string
hexadecimal. Todas exigem login de **treinador**; com outro perfil, retornam
`permission-denied`.

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
