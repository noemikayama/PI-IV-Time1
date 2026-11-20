# Contrato das callables do cadastro de treinamentos

Callables na região `southamerica-east1`. Todas, exceto `getTrainingDetails`,
exigem login de **treinador** com conta ativa; com outro perfil, retornam
`permission-denied` (conta inativa em `updateTraining` é `unauthenticated`,
como em `getTrainingDetails`). Os ids são
sempre strings hexadecimais e as datas vêm em ISO 8601 (UTC).

| Callable | Uso na tela |
| --- | --- |
| [listExerciseGallery](#listexercisegallery) | Galeria de exercícios (busca e filtro por cavalo) |
| `getTrainerProfile` (campo `cavalos`) | Opções do filtro de cavalo da galeria |
| [sumExerciseDurations](#sumexercisedurations) | "Tempo total dos exercícios selecionados" |
| [registerTraining](#registertraining) | Salvar o treinamento |
| [getTrainingDetails](#gettrainingdetails) | Detalhes do treino (treinador e responsável) e carga da tela "Editar treino" |
| [updateTraining](#updatetraining) | Salvar a edição do treino |

"Criar exercício" leva à tela de cadastro de exercício, que já existe
([contrato_exercicios.md](contrato_exercicios.md)). O exercício criado já
aparece na galeria na próxima chamada.

## Fluxo da tela

1. Na galeria, o treinador marca vários exercícios (seleção múltipla). O app
   junta os escolhidos à lista do treinamento, na ordem de execução.
2. Na etapa de duração, o app chama `sumExerciseDurations` com essa lista e
   mostra a soma. A soma é só informativa: o treinador digita a duração
   estimada que quiser (pode incluir descansos e deslocamentos).
3. O app chama `registerTraining` com os dados do formulário e a lista de ids.

## listExerciseGallery

```json
{ "busca": "trote", "cavaloId": "66e1a0c2f1b2c3d4e5f60050" }
```

Os dois campos são opcionais:

- **Sem `cavaloId`** (ausente, `null` ou `""`): lista os exercícios
  **genéricos** cadastrados pelo treinador.
- **Com `cavaloId`**: lista os exercícios **específicos** que o treinador
  cadastrou para esse cavalo. O cavalo precisa estar vinculado a ele.
- Para remover o filtro de cavalo, chame de novo sem `cavaloId`: a galeria
  volta aos genéricos.
- `busca`: mantém os exercícios cujo nome contém o texto, sem diferenciar
  maiúsculas, minúsculas e acentos (`"transicoes"` encontra "Transições
  trote-galope"). Até 80 caracteres; vazia lista todos.

Sem paginação: vem tudo, em ordem alfabética. Sem resultados, `exercicios` é
uma lista vazia (estado "Nenhum exercício criado").

```json
{
  "exercicios": [
    {
      "id": "66e1a0c2f1b2c3d4e5f6c010",
      "nome": "Transições trote-galope",
      "duracaoPadraoMinutos": 20,
      "privacidade": "ESPECIFICO",
      "cavalo": { "id": "66e1a0c2f1b2c3d4e5f60050", "codigo": "123123456789012", "nome": "Trovão" }
    }
  ]
}
```

`duracaoPadraoMinutos` é o "Tempo estimado" do card (a "Duração padrão" do
cadastro de exercício). `privacidade` é `GENERICO` ou `ESPECIFICO`, e `cavalo`
só existe no `ESPECIFICO` (`codigo` é o microchip).

| Erro | Quando |
| --- | --- |
| `invalid-argument` | `cavaloId` mal formado, `busca` longa demais ou campo desconhecido. |
| `permission-denied` | Cavalo sem vínculo com o treinador. |
| `not-found` | O cavalo não existe ou foi excluído. |

### Cavalos do filtro

Use a lista `cavalos` de `getTrainerProfile`, a mesma do seletor do cadastro de
exercício (`{ "_id", "codigo", "nome" }`). Envie o `_id` escolhido como
`cavaloId`.

## sumExerciseDurations

```json
{ "exercicios": ["66e1a0c2f1b2c3d4e5f6c011", "66e1a0c2f1b2c3d4e5f6c010"] }
```

Resposta: `{ "duracaoTotalMinutos": 30 }`, a soma de `duracaoPadraoMinutos`
dos exercícios. Lista vazia soma `0`. Um id repetido conta duas vezes.

Os mesmos erros de `exercicios` do `registerTraining` (abaixo), exceto o de
lista vazia.

## registerTraining

```json
{
  "titulo": "Trabalho de transições",
  "descricao": "Sessão focada em equilíbrio nas transições de andamento.",
  "exercicios": ["66e1a0c2f1b2c3d4e5f6c011", "66e1a0c2f1b2c3d4e5f6c010"],
  "orientacoes": ["Encerrar com 5 minutos de passo"],
  "duracaoEstimadaMinutos": 45
}
```

| Campo | Regra |
| --- | --- |
| `titulo` | Obrigatório, 3 a 80 caracteres (mínimo do dicionário de dados). |
| `descricao` | Opcional, até 1000 caracteres. Vazia ou só com espaços é ignorada. |
| `exercicios` | Ids dos exercícios, **na ordem de execução**. De 1 a 50. Todos precisam existir e ter sido cadastrados pelo treinador. Genéricos e específicos de cavalos diferentes podem ser misturados. |
| `orientacoes` | Opcional (lista vazia é aceita). Até 30 itens, cada um com 1 a 500 caracteres, sem item vazio. |
| `duracaoEstimadaMinutos` | Inteiro de 1 a 480 (minutos). Não precisa bater com a soma dos exercícios. |

Os textos têm os espaços das pontas removidos antes da validação.

Resposta: o treinamento criado, com os nomes de campo do dicionário de dados.

```json
{
  "id": "66e1a0c2f1b2c3d4e5f6d001",
  "codigo": 42,
  "titulo": "Trabalho de transições",
  "descricao": "Sessão focada em equilíbrio nas transições de andamento.",
  "orientacoes": ["Encerrar com 5 minutos de passo"],
  "duracaoEstimadaMinutos": 45,
  "treinador": { "id": "<uid>", "codigo": 92, "nome": "Carlos Mendes" },
  "exercicios": [
    {
      "id": "66e1a0c2f1b2c3d4e5f6c011",
      "codigo": 12,
      "nome": "Aquecimento ao passo",
      "descricao": "Caminhada em pista para aquecimento muscular.",
      "orientacoes": ["Deixar o pescoço solto"],
      "duracaoPadraoMinutos": 10
    }
  ],
  "criadoEm": "2026-11-14T14:30:00.000Z",
  "atualizadoEm": "2026-11-14T14:30:00.000Z"
}
```

`descricao` não vem quando não foi informada. Cada item de `exercicios` é uma
**cópia** do exercício no momento do cadastro (o `id` é o do exercício de
origem): editar o exercício depois não altera o treinamento.

| Erro | Quando |
| --- | --- |
| `invalid-argument` | Algum campo fora das regras acima. A mensagem diz qual. |
| `not-found` | Algum exercício não existe, foi excluído ou é de outro treinador. A mensagem lista os ids. |
| `permission-denied` | Conta inativa ou perfil diferente de treinador. |

## getTrainingDetails

Tela "Detalhes do treino", a mesma para o **treinador** e o **responsável**.
Diferente das callables acima, aceita os dois perfis. O cargo vem da conta no
MongoDB (o `_id` é o UID do token), nunca do app.

```json
{ "codigo": "42" }
```

`codigo` é o código sequencial do treinamento, enviado como string só com
dígitos (`"42"`). Outros campos são recusados.

Quem pode ver:

- **Treinador**: os treinamentos que ele cadastrou e os agendados para algum
  cavalo em que ele é o treinador.
- **Responsável**: os treinamentos agendados (registros de treino gerados por
  um plano) para algum cavalo em que ele é proprietário ou atleta.

Nos outros casos a resposta é `not-found`, como se o treinamento não
existisse.

Resposta:

```json
{
  "codigo": "42",
  "titulo": "Trabalho de transições",
  "descricao": "Sessão focada em equilíbrio nas transições de andamento.",
  "duracaoEstimada": 45,
  "exercicios": [
    {
      "codigo": "12",
      "nome": "Aquecimento ao passo",
      "duracao": 10,
      "descricao": "Caminhada em pista para aquecimento muscular.",
      "tipo": "especifico",
      "cavalo": { "codigo": "985141000123456", "nome": "Trovão" }
    }
  ],
  "orientacoes": ["Encerrar com 5 minutos de passo"],
  "cargo": "treinador"
}
```

| Campo | Observação |
| --- | --- |
| `descricao` | `""` quando o treinamento não tem descrição. |
| `duracaoEstimada` | Minutos (`duracaoEstimadaMinutos` do cadastro). |
| `exercicios` | Na ordem de execução. `duracao` é a duração padrão do exercício em minutos. O `codigo` identifica o exercício em `updateTraining`. |
| `exercicios[].tipo` | `generico` ou `especifico`. `null` para o responsável. |
| `exercicios[].cavalo` | Só no `especifico`: `codigo` (microchip) e `nome` do cavalo. `null` no `generico` e para o responsável. |
| `cargo` | `treinador` ou `responsavel`. O app mostra "Editar treino" só para `treinador`. |

Os dados são os do treinamento como está hoje, não a cópia guardada no plano.
A tela "Editar treino" usa esta mesma callable (não existe uma consulta
separada para a edição).

| Erro | Quando |
| --- | --- |
| `unauthenticated` | Sem login, ou conta inativa ou inexistente. |
| `invalid-argument` | `codigo` ausente, fora do formato ou campo desconhecido. |
| `not-found` | O treinamento não existe ou o usuário não tem acesso a ele. |

## updateTraining

Salva a tela "Editar treino". Recebe o **estado final completo** da tela, que
substitui o atual:

```json
{
  "codigo": "42",
  "titulo": "Trabalho de transições",
  "descricao": "Sessão focada em equilíbrio nas transições de andamento.",
  "duracaoEstimada": 45,
  "orientacoes": ["Encerrar com 5 minutos de passo"],
  "exercicioCodigos": ["12", "7"]
}
```

| Campo | Regra |
| --- | --- |
| `codigo` | Código do treinamento, string só com dígitos. |
| `titulo` | Obrigatório, de 3 a 80 caracteres (espaços nas pontas são removidos). |
| `descricao` | Obrigatório o campo, até 1000 caracteres. `""` remove a descrição. |
| `duracaoEstimada` | Inteiro de 1 a 480 minutos. |
| `orientacoes` | Obrigatório o campo (`[]` quando não houver), até 30 itens, cada um de 1 a 500 caracteres. |
| `exercicioCodigos` | De 1 a 50 códigos (strings só com dígitos), na ordem de execução. Um exercício pode aparecer mais de uma vez, como no cadastro. |

Outros campos são recusados. Como a edição substitui tudo, `descricao` e
`orientacoes` ausentes são recusados, para que um campo esquecido não apague
o conteúdo.

Quem pode editar: só **treinador**, e só se ele cadastrou o treinamento ou é
o treinador de algum cavalo com esse treinamento agendado (mesma regra de
`getTrainingDetails`).

Exercícios:

- Os que já estavam no treino continuam com a cópia guardada, mesmo que o
  exercício tenha sido editado ou excluído depois.
- Os novos precisam estar ativos e ter sido cadastrados pelo treinador que
  edita (mesma regra de `registerTraining`). Eles vêm de "Adicionar da
  galeria" ou "Criar exercício", que são telas próprias.
- Tirar um exercício do treino só desfaz o vínculo; o exercício não é apagado.

A edição também vale para o que ainda vai acontecer:

- **Planos** `RASCUNHO` ou `ATIVO`: a cópia do treino nos itens ativos do
  planejamento passa a ser a nova versão.
- **Registros de treino** `PLANEJADO` de hoje em diante e com todos os
  exercícios ainda `PENDENTE`: treino e exercícios passam a ser a nova versão.
- Registros de dias anteriores, registros com algum exercício já marcado,
  registros executados ou encerrados e planos `CONCLUIDO` ou `CANCELADO`
  guardam a versão antiga.

Resposta: o treinamento atualizado, no mesmo formato de
[getTrainingDetails](#gettrainingdetails), com `cargo: "treinador"`.

| Erro | Quando |
| --- | --- |
| `unauthenticated` | Sem login, ou conta inativa ou inexistente. |
| `invalid-argument` | Algum campo fora das regras acima, ou exercício que não existe, foi excluído ou é de outro treinador (a mensagem lista os códigos). |
| `permission-denied` | O usuário não é treinador. |
| `not-found` | O treinamento não existe ou o treinador não tem vínculo com ele. |
