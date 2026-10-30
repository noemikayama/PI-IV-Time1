# Contrato da callable do dashboard

Callable na região `southamerica-east1`. Datas de calendário em `AAAA-MM-DD`
(fuso de São Paulo) e `_id` sempre como string hexadecimal.

## getDashboard

Exige login. Responde ao **responsável** e ao **treinador**; a escolha é
feita pelo `role` do token, como em `getHome`, e a resposta traz `tipoConta`.

Todos os campos são opcionais: sem dados, a função responde o padrão da tela
(todos os cavalos, desde sempre, painel profissional desativado).

```json
{ "periodo": "MENSAL", "cavaloId": "66e1a0c2f1b2c3d4e5f60050" }
{ "periodo": "SEMANAL", "painelProfissional": true }
```

| Campo | Regra |
| --- | --- |
| `periodo` | `SEMPRE`, `DIARIO`, `SEMANAL`, `MENSAL`, `SEMESTRAL` ou `ANUAL`. Ausente ou `null` = `SEMPRE`. |
| `cavaloId` | `_id` de um cavalo do próprio usuário (`responsaveis.cavalos` ou `treinadores.cavalos`). Ausente ou `null` = todos os cavalos. |
| `painelProfissional` | Só para o treinador: botão "Painel profissional". `true` ou `false`; ausente ou `null` = `false`. Com `true`, `cavaloId` é recusado (o painel não filtra por cavalo). O responsável recebe `invalid-argument` se mandar `true`. |

Qualquer outro campo é recusado com `invalid-argument`, para que um nome
errado (`cavalo` em vez de `cavaloId`) não passe como "sem filtro".

### Períodos

Todas as janelas terminam no fim do dia de hoje, inclusive `SEMPRE`, então
nenhum treino futuro entra na conta e o dia corrente entra inteiro. Os dois
modos do treinador usam as mesmas janelas.

| `periodo` | Início da janela |
| --- | --- |
| `SEMPRE` | Sem início (`inicio: null`). |
| `DIARIO` | Hoje. |
| `SEMANAL` | Hoje - 6 dias (7 dias no total). |
| `MENSAL` | Hoje - 1 mês. |
| `SEMESTRAL` | Hoje - 6 meses. |
| `ANUAL` | Hoje - 12 meses. |

Um dia que não existe no mês de destino cai no último dia dele: em 31/03,
`MENSAL` começa em 28/02.

Datas de calendário (`dataPlanejada`, `dataExecucao`, `avaliacoes.data`) são
comparadas como dias. Campos com hora (`criadoEm`, `feedback.data`) são
comparados com o início e o fim do dia **em São Paulo**: um feedback às
22h30 de ontem (01h30 UTC de hoje) é de ontem.

### Resposta do responsável

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

Os percentuais são inteiros de 0 a 100, já arredondados. O arredondamento
não esconde os extremos: 100 só quando a parte atinge o total (199 de 200 é
99%) e 0 só quando a parte é zero (1 de 300 é 1%). As fatias de cada gráfico
de setores somam 100. As contagens que
originam cada um (`total`, `executados`, `previstos`,
`treinosConsiderados`) vêm junto, então a tela pode mostrar "5 de 8" sem
refazer a conta.

Erros: `unauthenticated` (sem login), `permission-denied` (conta inativa ou
perfil sem dashboard), `not-found` (cavalo que não é do usuário) e
`invalid-argument` (filtro inválido).

### Resposta do treinador — painel desativado (visão dos cavalos)

Mesmos cards e cálculos do responsável, sobre os cavalos de
`treinadores.cavalos`. Não há lista de feedbacks (a tela não a exibe).

```json
{
  "tipoConta": "TREINADOR",
  "painelProfissional": false,
  "periodo": "SEMANAL",
  "inicio": "2026-10-24",
  "fim": "2026-10-30",
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
  "cumprimentoTreinos": { "percentual": 90, "treinosConsiderados": 5 },
  "frequenciaExecucao": { "percentual": 71, "executados": 5, "previstos": 7 },
  "ultimosTreinos": [
    {
      "registroId": "66e1a0c2f1b2c3d4e5f6f101",
      "nomeTreino": "Trabalho de transições",
      "nomeCavalo": "Trovão",
      "nomePlano": "Condicionamento para percursos de 1,00 m",
      "data": "2026-10-29"
    }
  ],
  "possuiMaisTreinos": false
}
```

| Campo | Conteúdo |
| --- | --- |
| `possuiDados` | `false` sem cavalos vinculados ou sem treinos na janela: a tela mostra "Sem dados para exibir". Sem cavalos, `cavalos` vem vazio (a tela pode esconder os filtros). |
| `ultimosTreinos` | Até 5 treinos executados, do mais recente ao mais antigo. |
| `possuiMaisTreinos` | `true` quando há mais treinos executados na janela do que os listados: habilita o "Mostrar tudo". Os filtros aplicados (`periodo`, `inicio`, `fim`, `cavaloId`) vêm na resposta para a tela de histórico. |

### Resposta do treinador — painel profissional

Produção do próprio treinador na janela. Sem produção, os cards vêm zerados
(não há `possuiDados`: a tela mostra os zeros).

```json
{
  "tipoConta": "TREINADOR",
  "painelProfissional": true,
  "periodo": "SEMPRE",
  "inicio": null,
  "fim": "2026-10-30",
  "planosCriados": {
    "total": 7,
    "ativos": 5,
    "concluidos": 1,
    "cancelados": 1,
    "rascunhos": 0,
    "percentualAtivos": 71,
    "percentualConcluidos": 15,
    "percentualCancelados": 14,
    "percentualRascunhos": 0
  },
  "feedbacksDados": { "percentual": 76, "comFeedback": 19, "executados": 25 },
  "clientesVinculados": 13,
  "cavalosVinculados": 12,
  "avaliacoesFeitas": 19,
  "exerciciosCriados": 16
}
```

| Campo | Conteúdo |
| --- | --- |
| `planosCriados` | Gráfico "Planos criados": planos do treinador com `criadoEm` na janela, separados pelo status **atual**. `ativos` também alimenta o card "Planos ativos". Os quatro percentuais somam 100 (maior resto). |
| `feedbacksDados` | Registros `REALIZADO`/`PARCIAL` dos planos do treinador com `dataExecucao` na janela, e quantos já têm `feedback`. |
| `clientesVinculados`, `cavalosVinculados` | Tamanho atual de `treinadores.clientes` e `treinadores.cavalos`. **Não** são filtrados pelo período (ver lacunas). |
| `avaliacoesFeitas` | Avaliações com `treinador._id` do usuário e `data` na janela. |
| `exerciciosCriados` | Exercícios ativos com `treinador._id` do usuário e `criadoEm` na janela. |

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
- **Visão dos cavalos do treinador**: entram todos os registros dos cavalos
  que ele acompanha, inclusive de planos de outro treinador do mesmo cavalo
  (DD 5.2: o treinador acessa os registros dos cavalos que acompanha). Um
  cavalo desvinculado sai da visão junto com o seu histórico.
- **Painel profissional**: tudo é filtrado pela autoria (`treinador._id`),
  então entram também planos, avaliações e feedbacks de cavalos que o
  treinador já não acompanha: são produção dele.
- **Clientes e cavalos vinculados** não têm data de vínculo no DD, então não
  dá para filtrar pelo período: os dois cards mostram o vínculo atual em
  qualquer janela.
- **Planos criados** usam o status atual: um plano criado no mês e concluído
  hoje conta como concluído. O DD não guarda o histórico de status.
  `RASCUNHO` entra no total e vem como quarta fatia; a tela pode omiti-la.
- **Exercícios criados** contam só os ativos (os removidos são exclusão
  lógica), como o `totalExercicios` da home.
- **Feedbacks dados**: o DD permite feedback em `NAO_REALIZADO`, mas, como na
  home, o percentual considera só os executados (a base é "treinos que
  pedem feedback").
- O "Mostrar tudo" ainda não tem endpoint de histórico (RF10002); a resposta
  só informa se há mais itens e devolve os filtros aplicados.

### Consultas

Uma leitura em `responsaveis` (pelo `_id`, que é o UID) para o acesso e a
lista de cavalos, e uma agregação em `registros_treino` com `$facet`, que
resolve os três indicadores e as duas listas de uma vez. O `$match` inicial
usa `cavalo._id` e `status`, cobertos por `idx_registros_cavalo_data`, e
descarta os registros que não caem na janela de nenhum ramo, para que o
`$facet` (que não usa índice) não receba todo o histórico dos cavalos.
Responsável sem cavalos não chega a consultar `registros_treino`.

O treinador segue o mesmo caminho na visão dos cavalos, lendo `treinadores`
(cavalos, clientes e situação) e pulando o ramo de feedbacks do `$facet`. No
painel profissional, quatro consultas em paralelo:

| Indicador | Coleção | Índice |
| --- | --- | --- |
| Planos por status | `planos` | `idx_planos_treinador_status` |
| Feedbacks dados | `registros_treino` | `idx_registros_treinador_status` |
| Avaliações | `avaliacoes` | nenhum por treinador no DD; sugerido `(treinador._id, data)` |
| Exercícios | `exercicios` | `idx_exercicios_treinador` |
