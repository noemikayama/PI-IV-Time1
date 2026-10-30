# Contrato da callable do dashboard

Callable na região `southamerica-east1`. Datas de calendário em `AAAA-MM-DD`
(fuso de São Paulo) e `_id` sempre como string hexadecimal.

## getDashboard

Exige login. Hoje responde apenas ao **responsável**; o treinador cai em
`permission-denied` até que as funções de treino dele existam. A escolha é
feita pelo `role` do token, como em `getHome`.

Todos os campos são opcionais: sem dados, a função responde o padrão da tela
(todos os cavalos, desde sempre).

```json
{ "periodo": "MENSAL", "cavaloId": "66e1a0c2f1b2c3d4e5f60050" }
```

| Campo | Regra |
| --- | --- |
| `periodo` | `SEMPRE`, `DIARIO`, `SEMANAL`, `MENSAL`, `SEMESTRAL` ou `ANUAL`. Ausente ou `null` = `SEMPRE`. |
| `cavaloId` | `_id` de um cavalo do próprio responsável. Ausente ou `null` = todos os cavalos. |

Qualquer outro campo é recusado com `invalid-argument`, para que um nome
errado (`cavalo` em vez de `cavaloId`) não passe como "sem filtro".

### Períodos

Todas as janelas terminam no fim do dia de hoje, então nenhum treino futuro
entra na conta e o dia corrente entra inteiro.

| `periodo` | Início da janela |
| --- | --- |
| `SEMPRE` | Sem limite (`inicio: null`). |
| `DIARIO` | Hoje. |
| `SEMANAL` | Hoje - 6 dias (7 dias no total). |
| `MENSAL` | Hoje - 1 mês. |
| `SEMESTRAL` | Hoje - 6 meses. |
| `ANUAL` | Hoje - 12 meses. |

Um dia que não existe no mês de destino cai no último dia dele: em 31/03,
`MENSAL` começa em 28/02.

### Resposta

```json
{
  "tipoConta": "RESPONSAVEL",
  "periodo": "SEMPRE",
  "inicio": null,
  "fim": "2026-10-28",
  "cavaloId": null,
  "cavalos": [
    { "id": "66e1a0c2f1b2c3d4e5f60051", "nome": "Estrela do Sul" },
    { "id": "66e1a0c2f1b2c3d4e5f60050", "nome": "Trovão" }
  ],
  "possuiDados": true,
  "treinosRealizados": {
    "realizados": 4,
    "parciais": 1,
    "total": 5,
    "percentualRealizados": 80,
    "percentualParciais": 20
  },
  "cumprimentoTreinos": { "percentual": 80, "treinosConsiderados": 5 },
  "frequenciaExecucao": { "percentual": 63, "executados": 5, "previstos": 8 },
  "ultimosTreinos": [
    {
      "registroId": "66e1a0c2f1b2c3d4e5f6f101",
      "nomeTreino": "Trabalho de transições",
      "nomeCavalo": "Trovão",
      "nomePlano": "Condicionamento para percursos de 1,00 m",
      "data": "2026-10-28"
    }
  ],
  "ultimosFeedbacks": [
    {
      "registroId": "66e1a0c2f1b2c3d4e5f6f101",
      "nomeTreino": "Trabalho de transições",
      "nomePlano": "Condicionamento para percursos de 1,00 m",
      "data": "2026-10-27T20:00:00.000Z"
    }
  ]
}
```

| Campo | Conteúdo |
| --- | --- |
| `inicio`, `fim` | Janela aplicada. `inicio` é `null` em `SEMPRE`. |
| `cavalos` | Todos os cavalos do responsável, em ordem alfabética, para o seletor "Todos". Não é afetado pelo filtro. |
| `possuiDados` | `false` quando não há nada no período: a tela mostra "Sem dados para exibir". |
| `treinosRealizados` | Gráfico de setores. `total` é o número do centro (REALIZADO + PARCIAL) e os dois percentuais somam 100. |
| `cumprimentoTreinos` | Card "Percentual de cumprimento dos treinos". |
| `frequenciaExecucao` | Card "Frequência de execução dos treinos". |
| `ultimosTreinos` | Até 5 treinos executados, do mais recente ao mais antigo. `data` é a data de execução. |
| `ultimosFeedbacks` | Até 5 feedbacks recebidos, do mais recente ao mais antigo. `data` é o instante do feedback, em UTC (ISO 8601). |

Os percentuais são inteiros de 0 a 100, já arredondados. As contagens que
originam cada um (`total`, `executados`, `previstos`,
`treinosConsiderados`) vêm junto, então a tela pode mostrar "5 de 8" sem
refazer a conta.

Erros: `unauthenticated` (sem login), `permission-denied` (conta inativa ou
perfil sem dashboard), `not-found` (cavalo que não é do responsável) e
`invalid-argument` (filtro inválido).

### Como cada número é calculado

A fonte é a coleção `registros_treino`. Registros `CANCELADO` ficam fora de
tudo (DD 2.9). O responsável só enxerga os registros dos cavalos que estão
na sua lista `responsaveis.cavalos`, seja como proprietário ou atleta.

- **Treinos realizados**: registros `REALIZADO` e `PARCIAL` com
  `dataPlanejada` na janela.
- **Percentual de cumprimento**: média, entre os treinos executados, da razão
  `duracaoEfetivaMinutos / treinamento.duracaoEstimadaMinutos`, com cada
  razão limitada a 100% (RF10004 e RF10005). Entram apenas os executados que
  têm as duas durações; `treinosConsiderados` informa quantos foram.
- **Frequência de execução**: executados ÷ previstos, onde previstos são
  todos os registros não cancelados com `dataPlanejada` na janela. Como a
  janela termina hoje, o que ainda vai acontecer não pesa no indicador.
- **Últimos treinos**: executados com `dataExecucao` na janela, em ordem
  decrescente.
- **Últimos feedbacks**: registros com `feedback.data` na janela, em ordem
  decrescente.

Os três indicadores usam `dataPlanejada` como âncora do período, para que
"realizados" e "previstos" sempre falem do mesmo conjunto de sessões. As duas
listas usam a data do próprio evento, que é o que o card exibe.

### Decisões e lacunas

- O DD 2.9 chama de "percentual de cumprimento" a razão entre executados e
  previstos, enquanto o DD 5.2 e o RF10004 a definem pela razão entre
  duração efetiva e estimada. A tela tem os dois cards, então o indicador por
  duração ficou em **cumprimento** (RF10004/RF10005) e o indicador por
  contagem, em **frequência**.
- O DD 2.9 descreve frequência como "treinos realizados por semana do plano".
  A tela mostra um único percentual, e o filtro de período não é por plano,
  então a frequência virou o percentual acima. A quebra por semana
  (`registros_treino.semana`) continua disponível para uma versão futura.
- Um treino executado sem `duracaoEfetivaMinutos` ou sem
  `duracaoEstimadaMinutos` não entra no cumprimento (a razão não existe), mas
  continua contando nos outros indicadores.
- O dashboard do treinador ainda não existe. O handler já separa o fluxo por
  perfil e a resposta tem `tipoConta`, então basta acrescentar o service do
  treinador e o novo tipo à união `DashboardResult`.

### Consultas

Uma leitura em `responsaveis` (pelo `_id`, que é o UID) para o acesso e a
lista de cavalos, e uma agregação em `registros_treino` com `$facet`, que
resolve os três indicadores e as duas listas de uma vez. O `$match` inicial
usa `cavalo._id` e `status`, cobertos por `idx_registros_cavalo_data`.
Responsável sem cavalos não chega a consultar `registros_treino`.
