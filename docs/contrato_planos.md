# Contrato das callables de planos de treinamento

Callables na região `southamerica-east1`. Todas exigem login (sem login,
`unauthenticated`) e conta ativa (senão, `permission-denied`). A
[visualização](#gettrainingplandetails) atende treinador e responsável; as
demais exigem perfil de **treinador** e, com outro perfil, retornam
`permission-denied`. Os ids são sempre strings hexadecimais e as datas de
calendário vêm em `AAAA-MM-DD`.

Cadastro:

| Callable | Etapa |
| --- | --- |
| `listHorses` (perfil treinador) | Cavalo |
| [listHorseEvaluations](#listhorseevaluations) | Avaliação base (opcional) |
| [listTrainingGallery](#listtraininggallery) | Treinos por dia da semana |
| `registerTraining` ([contrato_treinamentos.md](contrato_treinamentos.md)) | "Criar novo treino" |
| [createTrainingPlan](#createtrainingplan) | Botão "Cadastrar plano" |

A revisão é montada no app; nada é gravado antes de `createTrainingPlan`.

Tela do plano:

| Callable | Uso |
| --- | --- |
| [getTrainingPlanDetails](#gettrainingplandetails) | Abrir a tela (treinador e responsável) |
| `getTrainingDetails` ([contrato_treinamentos.md](contrato_treinamentos.md)) | "Ver detalhes" de um treino |
| [updateTrainingPlan](#updatetrainingplan) | "Editar plano" (as mesmas callables do cadastro escolhem cavalo, avaliação e treinos) |
| [cancelTrainingPlan](#canceltrainingplan) | "Cancelar plano" |

## listHorseEvaluations

```json
{ "cavaloId": "66e1a0c2f1b2c3d4e5f60050" }
```

O cavalo precisa estar vinculado ao treinador (senão, `not-found`). Mais
recente primeiro; sem avaliações, a lista vem vazia.

```json
{ "avaliacoes": [{ "id": "66e1a0c2f1b2c3d4e5f6b003", "codigo": 42, "data": "2026-09-05" }] }
```

## listTrainingGallery

```json
{ "cavaloId": "66e1a0c2f1b2c3d4e5f60050", "busca": "trans" }
```

Treinamentos criados pelo treinador, em ordem alfabética, sem os que usam
exercício específico de **outro** cavalo. `busca` (opcional, até 80
caracteres) filtra por parte do título, sem diferenciar maiúsculas e
acentos. Sem resultados, a lista vem vazia ("Nenhum treinamento criado").

```json
{
  "treinamentos": [
    {
      "id": "66e1a0c2f1b2c3d4e5f6d001",
      "codigo": 42,
      "titulo": "Trabalho de transições",
      "duracaoEstimadaMinutos": 45,
      "exercicios": ["Aquecimento ao passo", "Transições trote-galope"]
    }
  ]
}
```

## createTrainingPlan

```json
{
  "titulo": "Condicionamento para percursos de 1,00 m",
  "objetivo": "Ganhar condicionamento para percursos de 1,00 m",
  "cavaloId": "66e1a0c2f1b2c3d4e5f60050",
  "avaliacaoId": null,
  "dataInicio": "2026-11-23",
  "dataFim": "2027-01-31",
  "treinosPorDia": {
    "SEGUNDA": "66e1a0c2f1b2c3d4e5f6d001",
    "TERCA": null,
    "QUARTA": "66e1a0c2f1b2c3d4e5f6d001",
    "QUINTA": null,
    "SEXTA": "66e1a0c2f1b2c3d4e5f6d002",
    "SABADO": null,
    "DOMINGO": null
  }
}
```

| Campo | Regra |
| --- | --- |
| `titulo` | 3 a 80 caracteres, sem contar espaços nas pontas |
| `objetivo` | 1 a 1000 caracteres |
| `cavaloId` | Cavalo ativo vinculado ao treinador |
| `avaliacaoId` | Opcional (`null`, `""` ou ausente). Precisa ser do mesmo cavalo |
| `dataInicio` | Hoje (fuso de São Paulo) ou depois |
| `dataFim` | A partir de `dataInicio`; o plano dura no máximo 12 meses |
| `treinosPorDia` | Id de um treinamento do treinador ou `null`; dia ausente = `null`. Pelo menos um dia com treino |

O plano nasce **ATIVO**. Os dias com o mesmo treino viram um item do
planejamento. Um registro de treino PLANEJADO é gerado para cada data do
período cujo dia da semana tenha treino.

```json
{
  "plano": {
    "id": "66e1a0c2f1b2c3d4e5f6e005",
    "codigo": 682,
    "status": "ATIVO",
    "dataInicio": "2026-11-23",
    "dataFim": "2027-01-31",
    "planejamento": [
      {
        "codigo": 1,
        "diasSemana": ["SEGUNDA", "QUARTA"],
        "treinamento": {
          "id": "66e1a0c2f1b2c3d4e5f6d001",
          "codigo": 42,
          "titulo": "Trabalho de transições",
          "descricao": "Sessão focada em equilíbrio.",
          "orientacoes": [],
          "duracaoEstimadaMinutos": 45,
          "exercicios": [
            { "id": "66e1a0c2f1b2c3d4e5f6c011", "codigo": 12, "nome": "Aquecimento ao passo", "descricao": "...", "orientacoes": [], "duracaoPadraoMinutos": 10 }
          ]
        }
      }
    ]
  },
  "registrosGerados": 30
}
```

### Erros exibíveis

| Código | Quando |
| --- | --- |
| `invalid-argument` | Campo inválido; nenhum dia com treino; nenhuma data do período cai em um dia com treino; treino com exercício específico de outro cavalo |
| `not-found` | Cavalo sem vínculo com o treinador; treinamento que não é do treinador; avaliação de outro cavalo |
| `failed-precondition` | O cavalo já tem um plano ativo em andamento ("Este cavalo já tem um plano ativo. Ele termina em DD/MM/AAAA.") |

Se o plano ativo do cavalo já venceu (`dataFim` antes de hoje), ele é
concluído no mesmo cadastro e o novo plano entra no lugar.

## getTrainingPlanDetails

Tela de visualização do plano, para os dois perfis. O `planoId` é o `id` que
o app já recebe em `planoAtual` (perfil do cavalo) e em `planosAtivos`
(agenda).

```json
{ "planoId": "66e1a0c2f1b2c3d4e5f6e005" }
```

Quem pode ver:

| Perfil | Acesso | `nomeTreinador` | Botões |
| --- | --- | --- | --- |
| Treinador autor do plano | Sempre, mesmo sem vínculo atual com o cavalo | Não vem | Editar e cancelar, conforme o status |
| Treinador atual do cavalo | Enquanto for o treinador do cavalo | Vem | Editar e cancelar, conforme o status |
| Responsável (proprietário ou atleta) | Enquanto tiver o vínculo com o cavalo | Vem | Nenhum |

Plano inexistente ou sem acesso retorna `not-found`; `planoId` inválido,
`invalid-argument`; conta inativa, `permission-denied`.

Exemplo para o treinador autor (sem `nomeTreinador`), consultado em
20/11/2026:

```json
{
  "role": "TREINADOR",
  "plano": {
    "id": "66e1a0c2f1b2c3d4e5f6e005",
    "codigo": 682,
    "titulo": "Condicionamento para percursos de 1,00 m",
    "objetivo": "Ganhar condicionamento para percursos de 1,00 m",
    "dataInicio": "2026-11-18",
    "dataFim": "2026-12-06",
    "status": "ATIVO"
  },
  "cavalo": { "id": "66e1a0c2f1b2c3d4e5f60050", "nome": "Trovão" },
  "permissoes": { "podeEditar": true, "podeCancelar": true },
  "avaliacao": { "id": "66e1a0c2f1b2c3d4e5f6b003", "codigo": 42, "data": "2026-11-10", "nomeCavalo": "Trovão" },
  "treinosDaSemana": {
    "dataInicio": "2026-11-16",
    "dataFim": "2026-11-22",
    "total": 1,
    "treinos": [
      {
        "data": "2026-11-18",
        "dataPorExtenso": "Quarta-feira, 18 de novembro de 2026",
        "diaSemana": "Quarta-feira",
        "treinamento": {
          "codigo": "42",
          "titulo": "Trabalho de transições",
          "duracaoEstimadaMinutos": 45,
          "descricao": "Sessão focada em equilíbrio.",
          "exercicios": ["Aquecimento ao passo", "Transições trote-galope"]
        }
      }
    ]
  },
  "todosOsTreinos": {
    "total": 5,
    "treinos": ["... mesmo formato, todas as datas do plano em ordem crescente"]
  },
  "treinosPorDia": {
    "SEGUNDA": { "id": "66e1a0c2f1b2c3d4e5f6d001", "codigo": 42, "titulo": "Trabalho de transições", "duracaoEstimadaMinutos": 45 },
    "TERCA": null,
    "QUARTA": { "id": "66e1a0c2f1b2c3d4e5f6d001", "codigo": 42, "titulo": "Trabalho de transições", "duracaoEstimadaMinutos": 45 },
    "QUINTA": null,
    "SEXTA": null,
    "SABADO": null,
    "DOMINGO": null
  }
}
```

Regras:

- `role`: `TREINADOR` ou `RESPONSAVEL`, lido da conta.
- `status`: um plano ATIVO cujo `dataFim` já passou aparece como `CONCLUIDO`.
- `podeEditar`: só o treinador, com o `status` acima em `RASCUNHO` ou
  `ATIVO`. `podeCancelar`: só o treinador, com o `status` acima `ATIVO`.
  Para o responsável, os dois são sempre `false`.
- `avaliacao`: `null` quando o plano não tem avaliação.
- `treinosDaSemana`: de segunda a domingo da semana atual (fuso de São
  Paulo). Vem vazia (`total` 0) enquanto o plano não começou.
- `todosOsTreinos` ("Ver tudo"): todas as datas do plano, inclusive de
  semanas passadas e futuras e de planos cancelados. `total` conta todas.
- Cada data mostra o treino que estava agendado nela: os dias passados (e um
  treino já começado hoje) não mudam quando o plano é editado. Num plano
  cancelado, as datas a partir do cancelamento mostram o que estava previsto.
- Cada treino é uma data. O mesmo treinamento aparece uma vez em cada dia
  da semana em que está no plano.
- `treinamento.codigo` vem como string, que é o que `getTrainingDetails`
  recebe no botão "Ver detalhes"
  ([contrato_treinamentos.md](contrato_treinamentos.md)).
  `descricao` vem `""` quando o treinamento não tem descrição, e
  `exercicios` traz os nomes na ordem de execução.
- `treinosPorDia`: o treino de cada dia, no formato da galeria (`codigo`
  numérico), para a tela de edição vir preenchida. O `id` é o que vai de
  volta em [updateTrainingPlan](#updatetrainingplan).

## updateTrainingPlan

Botão "Editar plano". Exige login de **treinador** (o responsável recebe
`permission-denied`): o autor do plano ou o treinador atual do cavalo, os
mesmos que recebem `podeEditar` na visualização. O pedido é o estado final
da tela, com os campos e as regras de `createTrainingPlan`, mais o
`planoId`.

```json
{
  "planoId": "66e1a0c2f1b2c3d4e5f6e005",
  "titulo": "Condicionamento para percursos de 1,10 m",
  "objetivo": "Ganhar condicionamento para percursos de 1,10 m",
  "cavaloId": "66e1a0c2f1b2c3d4e5f60050",
  "avaliacaoId": "66e1a0c2f1b2c3d4e5f6b003",
  "dataInicio": "2026-11-18",
  "dataFim": "2026-12-20",
  "treinosPorDia": {
    "SEGUNDA": "66e1a0c2f1b2c3d4e5f6d001",
    "TERCA": null,
    "QUARTA": null,
    "QUINTA": "66e1a0c2f1b2c3d4e5f6d009",
    "SEXTA": null,
    "SABADO": null,
    "DOMINGO": null
  }
}
```

- **Título, objetivo e datas**: mandar o valor novo (ou o atual, se não
  mudou).
- **Cavalo e avaliação**: escolhidos de novo com `listHorses` e
  `listHorseEvaluations`. A avaliação precisa ser do cavalo do plano
  (ao trocar o cavalo, escolher uma do cavalo novo ou mandar `null`);
  `null` tira a avaliação.
- **Treinos de cada dia**: `null` remove o treino do dia. Um treino novo
  vem da galeria (`listTrainingGallery`) ou é criado na hora
  (`registerTraining`) e entra pelo `id`. Os treinos que já estavam no plano
  são aceitos mesmo que sejam de outro treinador (o autor do plano).

Regras de data e cavalo:

| Situação | Data de início | Cavalo | Data de fim |
| --- | --- | --- | --- |
| Plano ainda não começou (`dataInicio` depois de hoje) | Hoje ou depois | Pode trocar: precisa estar vinculado ao treinador e sem outro plano em andamento (um plano vencido dele é concluído, como no cadastro) | Hoje ou depois |
| Plano já começou | Não muda | Não muda | Hoje ou depois |

A edição vale **de hoje em diante**:

- registros de treino de dias passados e os já começados ou executados não
  mudam (um registro começado hoje mantém o dia; nenhum outro é gerado
  nessa data);
- registros de hoje em diante que não fazem mais parte do plano (treino
  removido ou trocado, ou data fora do novo período) passam para
  `CANCELADO` (não aparecem na agenda nem no dashboard);
- os treinos novos geram registros `PLANEJADO`; os que continuam são
  renovados (inclusive o atleta atual do cavalo);
- o título novo é copiado em todos os registros do plano e no `planoAtual`
  do cavalo (que muda de cavalo, se ele foi trocado).

A resposta é a mesma de [getTrainingPlanDetails](#gettrainingplandetails),
já editada.

### Erros exibíveis

| Código | Quando |
| --- | --- |
| `invalid-argument` | Campo inválido (mesmas regras do cadastro); início no passado em plano que ainda não começou; fim antes de hoje; nenhuma data do período cai em um dia com treino; treino com exercício específico de outro cavalo |
| `not-found` | Plano inexistente ou sem vínculo com o treinador; cavalo sem vínculo com o treinador ("Cavalo não encontrado."); treinamento novo que não é do treinador; avaliação de outro cavalo ("Avaliação não encontrada para este cavalo.") |
| `failed-precondition` | "Este plano já terminou e não pode ser editado." (inclusive ATIVO com `dataFim` passada); "Este plano foi cancelado e não pode ser editado."; "A data de início não pode mudar depois que o plano começou."; "O cavalo não pode mudar depois que o plano começou."; o cavalo novo já tem um plano ativo em andamento ("Este cavalo já tem um plano ativo. Ele termina em DD/MM/AAAA.") |
| `permission-denied` | Perfil de responsável ou conta inativa |

## cancelTrainingPlan

Botão "Cancelar plano". Exige login de **treinador** (o responsável recebe
`permission-denied`): o autor do plano ou o treinador atual do cavalo, os
mesmos que recebem `podeCancelar` na visualização.

```json
{ "planoId": "66e1a0c2f1b2c3d4e5f6e005" }
```

Em uma única transação:

- o plano passa para `CANCELADO`;
- os registros de treino ainda `PLANEJADO` de hoje em diante (fuso de São
  Paulo) passam para `CANCELADO` e saem do percentual de cumprimento;
- os `PLANEJADO` de dias anteriores, que não foram feitos, passam para
  `NAO_REALIZADO`;
- registros já executados (`REALIZADO`, `PARCIAL` ou `NAO_REALIZADO`) não
  mudam;
- o cavalo fica sem `planoAtual`, e um novo plano pode ser criado para ele.

A resposta é a mesma de [getTrainingPlanDetails](#gettrainingplandetails),
já com `status` `CANCELADO` e os dois botões desligados, para o app trocar a
tela sem consultar de novo.

### Erros exibíveis

| Código | Quando |
| --- | --- |
| `invalid-argument` | `planoId` inválido |
| `not-found` | Plano inexistente ou sem vínculo com o treinador |
| `failed-precondition` | "Este plano já foi cancelado."; "Este plano já terminou e não pode ser cancelado." (inclusive ATIVO com `dataFim` passada); "Só planos ativos podem ser cancelados." (RASCUNHO) |
| `permission-denied` | Perfil de responsável ou conta inativa |
