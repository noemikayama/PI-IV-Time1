# Contrato das callables do cadastro de planos de treinamento

Callables na região `southamerica-east1`. Todas exigem login de **treinador**
com conta ativa; com outro perfil, retornam `permission-denied`. Os ids são
sempre strings hexadecimais e as datas de calendário vêm em `AAAA-MM-DD`.

| Callable | Etapa |
| --- | --- |
| `listHorses` (perfil treinador) | Cavalo |
| [listHorseEvaluations](#listhorseevaluations) | Avaliação base (opcional) |
| [listTrainingGallery](#listtraininggallery) | Treinos por dia da semana |
| `registerTraining` ([contrato_treinamentos.md](contrato_treinamentos.md)) | "Criar novo treino" |
| [createTrainingPlan](#createtrainingplan) | Botão "Cadastrar plano" |

A revisão é montada no app; nada é gravado antes de `createTrainingPlan`.

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
