# Contrato da callable da agenda de treinos

Callable na região `southamerica-east1`. Datas de calendário em `AAAA-MM-DD`
(fuso de São Paulo) e `_id` sempre como string hexadecimal (`id`).

## getTrainingAgenda

Exige login. Responde ao **treinador** e ao **responsável**; a escolha é
feita pelo `role` do token, como em `getHome`, e a resposta traz `role`.

A agenda mostra uma semana de **segunda a domingo**. Cada chamada devolve:

- `treinamentos`: a semana inteira, para a lista do dia selecionado no
  calendário (o front filtra pelo dia, sem chamar de novo);
- `treinosDoDia`: sempre os treinos de **hoje**, seja qual for a semana
  pedida (carrossel "Treinos do dia");
- `historicoExecucoes`: as execuções mais recentes, sem depender da semana.

Só há nova chamada ao navegar para a semana anterior ou a próxima.

```json
{}
{ "data": "2026-11-26" }
```

| Campo | Regra |
| --- | --- |
| `data` | Qualquer dia da semana desejada; o back calcula a segunda e o domingo dela. Ausente ou `null` = hoje. Para navegar, mande `semana.dataInicio` - 7 dias ou + 7 dias. |

Qualquer outro campo é recusado com `invalid-argument`.

### Resposta

Exemplo de um responsável que é atleta e proprietário do Trovão e só
proprietário da Estrela do Sul.

```json
{
  "role": "RESPONSAVEL",
  "hoje": "2026-11-19",
  "semana": { "dataInicio": "2026-11-16", "dataFim": "2026-11-22" },
  "planosAtivos": {
    "quantidade": 2,
    "planos": [
      {
        "id": "66e1a0c2f1b2c3d4e5f6a001",
        "titulo": "Condicionamento para percursos de 1,00 m",
        "nomeCavalo": "Trovão",
        "nomeTreinador": "Ana Souza",
        "dataInicio": "2026-11-03",
        "dataFim": "2027-01-31"
      },
      {
        "id": "66e1a0c2f1b2c3d4e5f6a002",
        "titulo": "Retorno após lesão",
        "nomeCavalo": "Estrela do Sul",
        "nomeTreinador": "Ana Souza",
        "dataInicio": "2026-11-10",
        "dataFim": "2026-12-20"
      }
    ]
  },
  "dias": [
    { "data": "2026-11-16", "quantidadeTreinos": 1 },
    { "data": "2026-11-17", "quantidadeTreinos": 0 },
    { "data": "2026-11-18", "quantidadeTreinos": 0 },
    { "data": "2026-11-19", "quantidadeTreinos": 2 },
    { "data": "2026-11-20", "quantidadeTreinos": 0 },
    { "data": "2026-11-21", "quantidadeTreinos": 0 },
    { "data": "2026-11-22", "quantidadeTreinos": 0 }
  ],
  "treinamentos": [
    {
      "id": "66e1a0c2f1b2c3d4e5f6f101",
      "nomeTreinamento": "Trabalho de transições",
      "nomeCavalo": "Trovão",
      "nomePlano": "Condicionamento para percursos de 1,00 m",
      "data": "2026-11-16",
      "status": "PARCIAL"
    },
    {
      "id": "66e1a0c2f1b2c3d4e5f6f102",
      "nomeTreinamento": "Ginástica no solo",
      "nomeCavalo": "Estrela do Sul",
      "nomePlano": "Retorno após lesão",
      "data": "2026-11-19",
      "status": "PLANEJADO"
    },
    {
      "id": "66e1a0c2f1b2c3d4e5f6f103",
      "nomeTreinamento": "Trabalho de transições",
      "nomeCavalo": "Trovão",
      "nomePlano": "Condicionamento para percursos de 1,00 m",
      "data": "2026-11-19",
      "status": "PLANEJADO"
    }
  ],
  "treinosDoDia": {
    "total": 2,
    "treinos": [
      {
        "id": "66e1a0c2f1b2c3d4e5f6f102",
        "nomeTreinamento": "Ginástica no solo",
        "nomeCavalo": "Estrela do Sul",
        "nomeTreinador": "Ana Souza",
        "duracaoEstimadaMinutos": 30,
        "nomePlano": "Retorno após lesão",
        "role": "PROPRIETARIO"
      },
      {
        "id": "66e1a0c2f1b2c3d4e5f6f103",
        "nomeTreinamento": "Trabalho de transições",
        "nomeCavalo": "Trovão",
        "nomeTreinador": "Ana Souza",
        "duracaoEstimadaMinutos": 45,
        "nomePlano": "Condicionamento para percursos de 1,00 m",
        "role": "ATLETA"
      }
    ]
  },
  "historicoExecucoes": [
    {
      "id": "66e1a0c2f1b2c3d4e5f6f101",
      "nomeTreinamento": "Trabalho de transições",
      "nomeCavalo": "Trovão",
      "data": "2026-11-16",
      "status": "PARCIAL"
    }
  ]
}
```

| Campo | Conteúdo |
| --- | --- |
| `role` | `TREINADOR` ou `RESPONSAVEL` (o mesmo `tipoConta` do `getHome`). |
| `hoje` | Hoje no fuso de São Paulo: o dia selecionado ao abrir a tela. Use este valor no lugar do relógio do aparelho. |
| `semana` | Segunda e domingo da semana consultada. |
| `planosAtivos` | Planos ATIVO ainda não vencidos (`dataFim` >= hoje), em ordem de início. **Não** dependem da semana. `nomeTreinador` só vem para o responsável. |
| `dias` | Sempre 7 itens, de segunda a domingo, inclusive os dias sem treino. |
| `treinamentos` | Todos os treinos da semana, em ordem de data (no mesmo dia, em ordem de criação). Treinos cancelados não aparecem. O botão "Ver detalhes" é o mesmo para todos e fica a cargo do front. |
| `treinamentos[].status` | `PLANEJADO`, `REALIZADO`, `PARCIAL` ou `NAO_REALIZADO`. Um treino de dia passado que continua `PLANEJADO` no banco sai como `NAO_REALIZADO`. |
| `treinosDoDia` | Treinos de hoje, na mesma ordem de `treinamentos`, e o `total`. Vêm mesmo quando a semana pedida não é a atual. `nomeTreinador` só vem para o responsável. |
| `treinosDoDia.treinos[].role` | Cargo do usuário naquele treino: `TREINADOR`, `ATLETA` ou `PROPRIETARIO`. Define o botão: `ATLETA` = "Iniciar treino"; `TREINADOR` e `PROPRIETARIO` = "Ver treino". |
| `historicoExecucoes` | Até 10 execuções (`REALIZADO` ou `PARCIAL`), da mais recente para a mais antiga, de qualquer data. `data` é a data de execução. Enquanto a execução não for implementada, vem vazio. |
| `id` (em todas as listas) | `_id` do registro de treino, para as telas futuras ("Ver treino", "Iniciar treino", detalhes da execução). O mesmo treino tem o mesmo `id` em `treinamentos`, `treinosDoDia` e `historicoExecucoes`. |

### Resposta do treinador

Mesmo formato, com `"role": "TREINADOR"` no topo e estas diferenças:

- `planosAtivos.planos[]` e `treinosDoDia.treinos[]` vêm **sem**
  `nomeTreinador`;
- `treinosDoDia.treinos[].role` é sempre `TREINADOR`.

### Regra do `role` em cada treino de hoje

O `role` do topo (`TREINADOR` ou `RESPONSAVEL`) diz o tipo de conta. O de
cada treino diz o cargo naquele treino, porque o responsável não tem um
papel único.

- Treinador: sempre `TREINADOR`.
- Responsável: depende das responsabilidades dele **no cavalo do treino**.
  Quem é atleta (mesmo que também seja proprietário) recebe `ATLETA`; quem
  é só proprietário recebe `PROPRIETARIO`. A mesma pessoa pode ser `ATLETA`
  em um cavalo e `PROPRIETARIO` em outro.

### O que cada perfil vê

- Treinador: planos, treinos e execuções em que ele é o treinador.
- Responsável: planos, treinos e execuções dos cavalos em que ele é atleta
  e/ou proprietário **hoje**. Como a consulta é por cavalo, um atleta novo
  também vê os treinos anteriores à troca, e quem deixou de ter vínculo com
  o cavalo deixa de ver os treinos dele.

### Estados vazios

| Seção | Dados | Estado vazio |
| --- | --- | --- |
| Resumo de planos | `planosAtivos` | `quantidade` = 0 |
| Treinamentos do dia selecionado | `treinamentos` filtrado por `data` | Nenhum: "Nenhum treino marcado" |
| Treinos do dia (hoje) | `treinosDoDia` | `total` = 0: "Nenhum treino marcado" |
| Histórico de execuções | `historicoExecucoes` | Vazio: "Nenhuma execução registrada" |

Erros: `unauthenticated` (sem login), `permission-denied` (conta inativa ou
perfil sem agenda) e `invalid-argument` (data fora do formato ou campo
desconhecido).

### Lacunas conhecidas

- Cavalo excluído: os treinos dele continuam na agenda do treinador (a
  exclusão não mexe nos registros). Para o responsável eles somem, porque o
  cavalo sai de `responsaveis.cavalos`.
