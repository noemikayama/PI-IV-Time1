# Contrato das callables de cavalos

Callables na região `southamerica-east1`. Datas sempre em `AAAA-MM-DD`
(fuso de São Paulo) e `_id` sempre como string hexadecimal.

## Visão geral

| Callable | Quem chama | Uso |
| --- | --- | --- |
| [registerHorse](#registerhorse) | Responsável proprietário | Cadastro |
| [listHorses](#listhorses) | Responsável ou treinador | Lista de cavalos (ordenação e busca) |
| [getHorseProfile](#gethorseprofile) | Proprietário, atleta ou treinador | Perfil inteiro: cabeçalho e abas "Dados", "Plano atual" e "Avaliações" |
| [updateHorse](#updatehorse) | Proprietário | "Editar animal" |
| [addHorseHealthEntry](#addhorsehealthentry) | Proprietário | "+ Adicionar" em saúde e lesões |
| [updateHorseLinks](#updatehorselinks) | Proprietário | "Editar vínculos" |
| [removeHorseLink](#removehorselink) | Proprietário | Desvincular o atleta ou o treinador |
| [deleteHorse](#deletehorse) | Proprietário | "Excluir animal" |
| [Imagens](#imagens) | Proprietário | Envio e remoção de fotos |

O perfil é carregado por **uma** chamada (`getHorseProfile`) e as três abas
usam a mesma resposta. As edições feitas no perfil (`updateHorse`,
`addHorseHealthEntry`, `updateHorseLinks` e `removeHorseLink`) respondem com o perfil atualizado,
no mesmo formato: basta substituir o estado da tela, sem consultar de novo. A
criação de avaliações (`createHorseEvaluation`) está em
[contrato_avaliacoes.md](contrato_avaliacoes.md).

## Acesso

Todas as callables aplicam as mesmas regras, nesta ordem:

| Situação | Resposta |
| --- | --- |
| Conta inativa (responsável fora de `ATIVO`, treinador `INATIVO`) ou papel sem acesso | `permission-denied` |
| Cavalo inexistente, excluído ou sem vínculo com quem chama | `not-found` |
| Quem chama tem vínculo, mas não a relação exigida (ex.: atleta tentando editar) | `permission-denied` |

Um cavalo de terceiros é sempre tratado como inexistente, para não revelar que
ele existe. A relação de quem chama é `PROPRIETARIO` e/ou `ATLETA`, ou
`TREINADOR`, e volta em `responsabilidades` nas consultas.

Matriz de permissões (conferida em cada callable; o perfil devolve o resultado
em `permissoes`):

| Operação | Proprietário | Treinador | Atleta |
| --- | --- | --- | --- |
| Consultar o perfil (dados, plano atual, avaliações) | Sim | Sim | Sim |
| Editar dados, imagens e remover itens de saúde | Sim | Não | Não |
| Incluir limitação, observação ou lesão | Sim | Não | Não |
| Excluir o cavalo | Sim | Não | Não |
| Alterar treinador e atleta | Sim | Não | Não |
| Criar avaliação | Não | Sim | Não |

## registerHorse

Exige login de **responsável**. Só cadastra quem é proprietário: se
`responsabilidades` não contiver `PROPRIETARIO`, retorna `permission-denied`.

```json
{
  "codigo": "123123456789012",
  "responsabilidades": ["PROPRIETARIO", "ATLETA"],
  "nome": "Trovão",
  "dataNascimento": "2016-04-10",
  "raca": "Brasileiro de Hipismo",
  "pelagem": "Tordilho",
  "sexo": "MACHO",
  "modalidadeId": "66e1a0c2f1b2c3d4e5f6a001",
  "limitacoesFisicas": ["Sensibilidade no casco posterior esquerdo"],
  "observacoesSaude": ["Vacinas em dia"],
  "historicoLesoes": [
    {
      "data": "2025-03-12",
      "descricao": "Distensão leve",
      "prescricao": "Repouso de 3 semanas"
    }
  ]
}
```

| Campo | Regra |
| --- | --- |
| `codigo` | Microchip: exatamente 15 dígitos, único entre todos os cavalos, inclusive os excluídos (`already-exists` se repetido). |
| `responsabilidades` | `["PROPRIETARIO"]` ou `["PROPRIETARIO", "ATLETA"]`. |
| `nome` | 2 a 80 caracteres. |
| `dataNascimento` | Data válida, não futura, até 50 anos atrás. |
| `raca`, `pelagem` | 1 a 60 caracteres (aceita `SRD` / `SPD`). |
| `sexo` | `MACHO` ou `FEMEA`. |
| `modalidadeId` | Obrigatório. `_id` vindo de `getModalities`. |
| `limitacoesFisicas`, `observacoesSaude` | Opcionais. Até 30 itens, sem item vazio. |
| `historicoLesoes` | Opcional. `data` e `descricao` obrigatórias; `prescricao` opcional. A data não pode ser futura nem anterior ao nascimento. |

Resposta: `{ "id": "...", "codigo": "123123456789012", "nome": "Trovão" }`.

O cavalo é criado com `imagens: []`. As imagens são enviadas depois, com o
`id` devolvido aqui (ver [Imagens](#imagens)).

## updateHorse

Exige login de **responsável** e só pode ser chamada pelo proprietário. Envie
`id` e apenas os campos que mudaram: um campo ausente não é alterado. Os campos
seguem as regras do cadastro: a modalidade não pode ser removida
(`modalidadeId` nulo retorna `invalid-argument`) e um microchip (`codigo`) já
usado por outro cavalo retorna `already-exists`. `responsabilidades` não pode
ser editado; os vínculos mudam em [updateHorseLinks](#updatehorselinks).

As listas (`limitacoesFisicas`, `observacoesSaude` e `historicoLesoes`) não são
enviadas inteiras: cada uma recebe `{ "adicionar": [...], "remover": [...] }`,
aplicado sobre a lista gravada no momento da edição. Assim, uma tela
desatualizada não apaga o que outra pessoa incluiu nesse meio-tempo.

```json
{ "id": "66e1a0c2f1b2c3d4e5f60050", "nome": "Trovão II", "modalidadeId": null }
```

Resposta: o cavalo atualizado, no mesmo formato de `getHorse`.

## getHorseProfile

Exige login. Responde ao proprietário, ao atleta e ao treinador do cavalo e
traz tudo o que o perfil exibe: cabeçalho e as abas "Dados", "Plano atual" e
"Avaliações".

```json
{ "id": "66e1a0c2f1b2c3d4e5f60050" }
```

Resposta (proprietário que também é atleta):

```json
{
  "id": "66e1a0c2f1b2c3d4e5f60050",
  "codigo": "123123456789012",
  "nome": "Trovão",
  "imagens": [{ "caminho": "/fotos/cavalos/.../imagem_1.jpg", "url": "https://..." }],
  "dataNascimento": "2016-04-10",
  "idade": { "anos": 10, "meses": 6 },
  "raca": "Brasileiro de Hipismo",
  "pelagem": "Tordilho",
  "sexo": "MACHO",
  "modalidade": { "id": "...", "codigo": 12, "nome": "Salto" },
  "limitacoesFisicas": ["Sensibilidade no casco posterior esquerdo"],
  "observacoesSaude": ["Vacinas em dia"],
  "historicoLesoes": [
    { "data": "2025-03-12", "descricao": "Distensão leve", "prescricao": "Repouso de 3 semanas" }
  ],
  "proprietario": { "id": "...", "codigo": 7, "nome": "Maria Oliveira" },
  "atleta": { "id": "...", "codigo": 7, "nome": "Maria Oliveira" },
  "treinador": { "id": "...", "codigo": 92, "nome": "Carlos Mendes" },
  "responsabilidades": ["PROPRIETARIO", "ATLETA"],
  "permissoes": {
    "editar": true,
    "adicionarSaude": true,
    "excluir": true,
    "gerenciarVinculos": true,
    "criarAvaliacao": false,
    "acaoTreino": "INICIAR"
  },
  "planoAtual": {
    "id": "...", "codigo": 682, "titulo": "Condicionamento para percursos de 1,00 m",
    "dataInicio": "2026-09-07", "dataFim": "2026-10-04",
    "treinoDoDia": {
      "situacao": "PENDENTE",
      "treino": {
        "registroId": "...",
        "nomeTreino": "Trabalho de transições",
        "nomePlano": "Condicionamento para percursos de 1,00 m",
        "duracaoMinutos": 45,
        "pessoa": { "papel": "TREINADOR", "nome": "Carlos Mendes" },
        "status": "PLANEJADO"
      }
    }
  },
  "avaliacoes": [
    {
      "id": "66e1a0c2f1b2c3d4e5f6b003",
      "codigo": 42,
      "data": "2026-09-05",
      "treinador": { "id": "...", "codigo": 92, "nome": "Carlos Mendes" }
    }
  ],
  "atualizadoEm": "2026-11-03T12:30:00.000Z"
}
```

**Cabeçalho.** `nome` e a primeira de `imagens` (pode não haver nenhuma).

**Aba "Dados".**

- `codigo` é o microchip e só vem para o proprietário; para atleta e
  treinador vem `null`.
- `idade` é calculada a cada consulta a partir de `dataNascimento`.
- `atleta`, `treinador` e `modalidade` vêm `null` quando não existem
  (`modalidade` só em cavalos cadastrados antes de ela ser obrigatória).
- O nome do plano ativo é `planoAtual.titulo`.
- `imagens` vem na ordem de envio. A `url` é assinada e vale 15 minutos; o
  `caminho` identifica a imagem para removê-la.

**Permissões.** `permissoes` diz quais ações exibir. São calculadas pelas
mesmas regras que as callables conferem, então o app não precisa reproduzir a
matriz de [Acesso](#acesso):

| Campo | Botão |
| --- | --- |
| `editar` | "Editar animal" (campos, imagens e remoção de itens de saúde) |
| `adicionarSaude` | "+ Adicionar" em limitações, observações e lesões |
| `excluir` | "Excluir animal" |
| `gerenciarVinculos` | "Editar vínculos" |
| `criarAvaliacao` | "Nova avaliação" (só o treinador) |
| `acaoTreino` | Botão do card do treino: `INICIAR` para o atleta (inclusive quando também é proprietário), `VER` para os demais |

**Aba "Plano atual".** `planoAtual` é `null` quando o cavalo não tem plano
`ATIVO`. Com plano, `treinoDoDia.situacao` diz explicitamente o estado do
treino de hoje (fuso de São Paulo), sem o app precisar deduzi-lo:

| `situacao` | Quando | `treino` |
| --- | --- | --- |
| `SEM_TREINO` | Nenhum registro hoje nesse plano (cancelados não contam) | `null` |
| `PENDENTE` | Treino ainda não feito: `status` `PLANEJADO` (ou `NAO_REALIZADO`) | Card do treino |
| `CONCLUIDO` | Treino feito: `status` `REALIZADO` ou `PARCIAL` | Card do treino |

Só os registros de hoje são considerados: o treino de um dia que já passou
não aparece, tenha sido feito ou não. `treino.status` traz o detalhe do
registro, se a tela quiser diferenciar um treino parcial. `treino.pessoa` já
vem resolvida pelo perfil de quem consulta: o **atleta** para o treinador, o
**treinador** para o proprietário e o atleta; `pessoa.nome` vem `null` se o
registro não tiver essa pessoa. Se houver mais de um registro no dia, vem o
primeiro ainda pendente; sem pendentes, o último concluído.

**Aba "Avaliações".** `avaliacoes` traz o histórico completo em ordem
cronológica decrescente (RF06003). O cabeçalho do card usa o `nome` (ou o
`codigo`, para o proprietário) do próprio cavalo.

## updateHorseLinks

Exige login de **responsável** e só pode ser chamada pelo proprietário. Vincula
o atleta e/ou o treinador pelo e-mail de cadastro. O vínculo é imediato, sem
aceite, e substitui o anterior. O cavalo tem um único treinador. O proprietário
pode informar o próprio e-mail como atleta. Um campo ausente ou vazio mantém o
vínculo atual.

```json
{
  "id": "66e1a0c2f1b2c3d4e5f60050",
  "emailTreinador": "carlos.mendes@example.com",
  "emailAtleta": "maria.oliveira@example.com"
}
```

Resposta: o perfil atualizado, no mesmo formato de `getHorseProfile`.

| Situação | Resposta |
| --- | --- |
| Nenhum e-mail informado, ou e-mail mal formatado | `invalid-argument` |
| Nenhuma conta com o e-mail | `not-found` |
| E-mail de treinador no campo do atleta, ou o contrário | `invalid-argument` |
| Conta do atleta ou do treinador inativa | `failed-precondition` |
| O treinador que sai é autor do plano `ATIVO` do cavalo (RF05003) | `failed-precondition` |

Na mesma transação, são atualizados `responsaveis.cavalos` do atleta antigo e
do novo, `treinadores.cavalos` do treinador antigo e do novo, e
`treinadores.clientes` (proprietário e atleta) de cada treinador afetado.

Para deixar o cavalo sem atleta ou sem treinador, use
[removeHorseLink](#removehorselink).

## removeHorseLink

Exige login de **responsável** e só pode ser chamada pelo proprietário.
Desfaz um vínculo por chamada: `vinculo` é `ATLETA` ou `TREINADOR`.

```json
{ "id": "66e1a0c2f1b2c3d4e5f60050", "vinculo": "TREINADOR" }
```

Resposta: o perfil atualizado, no mesmo formato de `getHorseProfile`, com
`atleta` ou `treinador` em `null`.

| Situação | Resposta |
| --- | --- |
| `vinculo` diferente de `ATLETA` ou `TREINADOR` | `invalid-argument` |
| O cavalo não tem o vínculo informado | `not-found` |
| O treinador é autor do plano `ATIVO` do cavalo (RF05003) | `failed-precondition` |

Na mesma transação, são atualizados `responsaveis.cavalos` do atleta (se ele
também for o proprietário, só perde a responsabilidade `ATLETA`),
`treinadores.cavalos` do treinador e `treinadores.clientes` de cada treinador
afetado.

## listHorses

Exige login de **responsável** ou **treinador**. Lista os cavalos ativos em que
o responsável é proprietário ou atleta, ou que o treinador acompanha.

```json
{ "ordenacao": "A_Z", "busca": "tro" }
```

Os dois campos são opcionais e valem juntos, na mesma tela:

- `ordenacao` (padrão `A_Z`): `A_Z`, `Z_A`, `MAIS_RECENTES` ou
  `MAIS_ANTIGOS`. As datas são as do vínculo de quem consulta: o cadastro do
  cavalo para o proprietário e a data do vínculo para atleta e treinador.
- `busca` (RF04014): mantém só os cavalos cujo nome contém o texto, sem
  diferença de maiúsculas, minúsculas e acentos (`"tro"` e `"TROVAO"` encontram
  "Trovão"). Até 80 caracteres; vazia lista todos. Sem resultados, `cavalos`
  vem como lista vazia.

Resposta do responsável:

```json
{
  "tipoConta": "RESPONSAVEL",
  "cavalos": [
    {
      "id": "66e1a0c2f1b2c3d4e5f60050",
      "nome": "Trovão",
      "foto": { "caminho": "/fotos/cavalos/.../imagem_1.jpg", "url": "https://..." },
      "modalidade": { "id": "...", "codigo": 12, "nome": "Salto" },
      "responsabilidades": ["PROPRIETARIO", "ATLETA"],
      "vinculadoEm": "2026-08-25T12:30:00.000Z",
      "treinador": { "id": "...", "codigo": 92, "nome": "Carlos Mendes" }
    }
  ]
}
```

A resposta do treinador traz `"tipoConta": "TREINADOR"`, `responsabilidades`
igual a `["TREINADOR"]` e `proprietario` no lugar de `treinador`. `foto` é a
primeira imagem do cavalo, ou `null`. `treinador` e `modalidade` podem ser
`null`.

## addHorseHealthEntry

Exige login de **responsável** e só pode ser chamada pelo proprietário, que
**inclui** um item em uma lista de saúde (editar e remover ficam em
`updateHorse`). O item é acrescentado sem regravar a lista, então inclusões
simultâneas não se perdem.

```json
{ "id": "66e1a0c2f1b2c3d4e5f60050", "lista": "observacoesSaude", "item": "Vacinas em dia" }
```

```json
{
  "id": "66e1a0c2f1b2c3d4e5f60050",
  "lista": "historicoLesoes",
  "item": { "data": "2025-03-12", "descricao": "Distensão leve", "prescricao": "Repouso de 3 semanas" }
}
```

`lista` é `limitacoesFisicas`, `observacoesSaude` ou `historicoLesoes`. O
`item` segue as regras do cadastro. Item já presente na lista (sem diferença de
maiúsculas e minúsculas), lista no limite ou lesão anterior ao nascimento
retornam `invalid-argument`.

Resposta: o perfil atualizado, no mesmo formato de `getHorseProfile`.

## deleteHorse

Exige login de **responsável** e só pode ser chamada pelo proprietário.

```json
{ "id": "66e1a0c2f1b2c3d4e5f60050" }
```

Resposta: `{ "excluido": true }`. A exclusão é lógica: o cavalo passa a
`INATIVO` e some de `getHorseProfile`, `listHorses` e das demais callables
(`not-found`). Na mesma transação, ele sai de `responsaveis.cavalos` do
proprietário e do atleta e de `treinadores.cavalos`, e os clientes dos
treinadores são recalculados. Imagens, avaliações, planos e registros são
preservados, e o microchip não pode ser usado em outro cadastro.

## Imagens

Exigem login de **responsável** e só podem ser chamadas pelo proprietário
(ver [Acesso](#acesso)). O fluxo é o mesmo dos PDFs do treinador:
o app envia os bytes direto ao Storage por uma URL assinada.

Para cada imagem, o app:

1. chama `createHorseImageUpload` com `id` e `contentType`;
2. recebe `caminho`, `uploadUrl` e os headers obrigatórios;
3. envia os bytes por `PUT` para `uploadUrl`, com esses headers, em até 10
   minutos;
4. chama `confirmHorseImage` com `id` e `caminho`.

Envie os headers exatamente como recebidos. A URL só aceita o envio se ainda
não houver arquivo no caminho: um segundo `PUT` para o mesmo caminho é recusado
pelo Storage com `412`. Para trocar uma imagem, remova-a e peça uma nova URL.

Prefira enviar as imagens uma de cada vez. O backend escolhe o menor índice
livre e pula os caminhos de envios feitos e ainda não confirmados. Se dois
pedidos simultâneos receberem o mesmo caminho, o segundo `PUT` recebe `412`:
peça outra URL e reenvie. Um envio não confirmado em 30 minutos é considerado
abandonado e o caminho volta a ficar livre.

| Regra | Valor |
| --- | --- |
| Formatos | `image/jpeg` ou `image/png` (o conteúdo é conferido). |
| Tamanho | Até 5 MB. |
| Quantidade | Até 10 por cavalo. |
| Caminho | `/fotos/cavalos/<id>/imagem_<n>.jpg` (ou `.png`). |

### createHorseImageUpload

```json
{ "id": "66e1a0c2f1b2c3d4e5f60050", "contentType": "image/jpeg" }
```

Resposta:

```json
{
  "caminho": "/fotos/cavalos/66e1a0c2f1b2c3d4e5f60050/imagem_1.jpg",
  "uploadUrl": "https://storage.googleapis.com/...",
  "headers": {
    "Content-Type": "image/jpeg",
    "x-goog-content-length-range": "0,5242880",
    "x-goog-if-generation-match": "0"
  }
}
```

Com 10 imagens confirmadas, retorna `invalid-argument`. Se todos os índices
livres estiverem ocupados por envios ainda não confirmados, retorna
`failed-precondition`.

### confirmHorseImage

```json
{
  "id": "66e1a0c2f1b2c3d4e5f60050",
  "caminho": "/fotos/cavalos/66e1a0c2f1b2c3d4e5f60050/imagem_1.jpg"
}
```

Resposta: `{ "caminho": "...", "url": "..." }`. Retorna `not-found` se o
arquivo não foi enviado. Se o arquivo não for uma imagem válida, ele é apagado
e a resposta é `invalid-argument`.

### removeHorseImage

Mesmo corpo de `confirmHorseImage`. Apaga a imagem do cavalo e do Storage e
responde `{ "removido": true }`, ou `not-found` se ela não estiver no cavalo ou
se o cavalo tiver sido excluído.
