# Contrato da execução e do feedback de treinos

Callables na região `southamerica-east1`. Nas respostas, `_id` vira `id`
(hexadecimal); códigos de treinamento e de exercício vêm como string só com
dígitos, como em `getTrainingDetails`; dias vêm como `AAAA-MM-DD` (fuso de
São Paulo); instantes, em ISO 8601 (UTC). Durações em minutos.

Um **treino agendado** é um registro de treino: a sessão de um plano para
um cavalo em um dia. O `registroId` usado aqui é o `id` que o app já
recebe da agenda (`treinamentos`, `treinosDoDia`, `historicoExecucoes`), do
perfil do cavalo (`planoAtual.treinoDoDia.treino.registroId`), do
dashboard (`registroId`) e de `listPendingFeedbacks`.

| Callable | Quem chama | Tela |
| --- | --- | --- |
| `getTrainingRecord` | Treinador ou responsável | "Execução do treinamento" (antes e durante), "Visualização da execução" e "Visualização de feedback" |
| `registerTrainingExecution` | Atleta do cavalo | "Treino concluído" → "Submeter registro" |
| `registerTrainingFeedback` | Treinador do plano | "Registro de feedback" → "Registrar feedback" |
| `listPendingFeedbacks` | Treinador | Execuções que esperam feedback |

## Quem pode o quê

| Quem pede | Ver | Registrar execução | Registrar feedback |
| --- | --- | --- | --- |
| Atleta do cavalo (inclusive se também for proprietário) | Sim | Só o treino de **hoje**, ainda `PLANEJADO` | `permission-denied` |
| Proprietário que não é o atleta | Sim | `permission-denied` | `permission-denied` |
| Treinador do plano (mesmo sem vínculo atual ou com o cavalo excluído) | Sim | `permission-denied` | Treino com relato do atleta e sem feedback |
| Outro treinador vinculado ao cavalo | Sim | `permission-denied` | `permission-denied` |
| Sem vínculo, ou cavalo excluído (exceto o treinador do plano) | `not-found` | `not-found` | `not-found` |
| Conta inativa | `permission-denied` | `permission-denied` | `permission-denied` |

Os botões vêm prontos em `permissoes` (abaixo). Use-os em vez de deduzir a
regra no app, inclusive no perfil do cavalo, onde o card do treino de hoje
continua mostrando "Iniciar treino" num treino que o atleta já registrou
como não realizado.

A execução e o feedback são **imutáveis** (RF09011, RF09014): cada treino
aceita uma execução e um feedback, que depois não mudam. Por isso a
confirmação antes de cada envio (RF09013, RF09015) é obrigatória no app.

## getTrainingRecord

Exige login.

```json
{ "registroId": "66e1a0c2f1b2c3d4e5f6f103" }
```

Resposta para o atleta, no treino de hoje, antes da execução:

```json
{
  "role": "RESPONSAVEL",
  "registro": {
    "id": "66e1a0c2f1b2c3d4e5f6f103",
    "codigo": 812,
    "status": "PLANEJADO",
    "dataPlanejada": "2026-11-21"
  },
  "plano": {
    "id": "66e1a0c2f1b2c3d4e5f6e005",
    "titulo": "Condicionamento para percursos de 1,00 m",
    "objetivo": "Ganhar condicionamento para percursos de 1,00 m"
  },
  "treinamento": {
    "codigo": "42",
    "titulo": "Trabalho de transições",
    "descricao": "Transições de passo, trote e galope.",
    "orientacoes": ["Encerrar com 5 minutos de passo."],
    "duracaoEstimada": 40
  },
  "cavalo": { "id": "66e1a0c2f1b2c3d4e5f60050", "nome": "Trovão" },
  "treinador": { "nome": "Ana Souza" },
  "atleta": { "nome": "Bruno Lima" },
  "exercicios": [
    {
      "posicao": 1,
      "codigo": "17",
      "nome": "Transições trote-galope",
      "descricao": "Alternar trote e galope a cada lado da pista.",
      "orientacoes": ["Manter contato leve com as rédeas"],
      "duracao": 15,
      "realizacao": "PENDENTE",
      "observacao": null,
      "materiais": [{ "descricao": "Cavalete", "quantidade": 3 }],
      "midias": {
        "imagens": [{ "caminho": "/fotos/exercicios/...", "url": "https://..." }],
        "videos": [{ "caminho": "/videos/exercicios/...", "url": "https://..." }],
        "semMidias": false
      }
    },
    {
      "posicao": 2,
      "codigo": "23",
      "nome": "Volta ao passo",
      "descricao": "Passo livre com rédeas longas.",
      "orientacoes": [],
      "duracao": 10,
      "realizacao": "PENDENTE",
      "observacao": null,
      "materiais": [],
      "midias": { "imagens": [], "videos": [], "semMidias": true }
    }
  ],
  "execucao": null,
  "feedback": null,
  "permissoes": { "podeRegistrarExecucao": true, "podeRegistrarFeedback": false }
}
```

Depois da execução e do feedback (só os campos que mudam):

```json
{
  "registro": { "id": "...", "codigo": 812, "status": "PARCIAL", "dataPlanejada": "2026-11-21" },
  "execucao": {
    "dataExecucao": "2026-11-21",
    "duracaoEfetiva": 50,
    "percepcaoDesempenho": 8,
    "dificuldades": "Complicações quando está na mão esquerda",
    "observacoes": ["Cavalo mais agitado no início"],
    "exerciciosRealizados": 1,
    "exerciciosNaoRealizados": 1
  },
  "feedback": {
    "data": "2026-11-21T22:15:00.000Z",
    "comentario": "Boa resposta às transições.",
    "dificuldadesIdentificadas": ["Perda de equilíbrio na mão esquerda."],
    "orientacoes": ["Reforçar o trabalho bilateral."]
  },
  "permissoes": { "podeRegistrarExecucao": false, "podeRegistrarFeedback": false }
}
```

| Campo | Regra |
| --- | --- |
| `role` | `TREINADOR` ou `RESPONSAVEL`, o tipo de conta. Na "Visualização da execução", o treinador vê o rótulo "Atleta" e o responsável, "Treinador". |
| `registro.status` | `PLANEJADO`, `REALIZADO`, `PARCIAL`, `NAO_REALIZADO` ou `CANCELADO`. Um `PLANEJADO` de dia anterior a hoje sai `NAO_REALIZADO`, como na agenda. |
| `plano.objetivo` | O "Objetivo" da "Visualização da execução". |
| `treinamento` e `exercicios[]` (nome, descrição, orientações, duração) | Cópia guardada no treino quando ele foi agendado, não a versão atual. `descricao` vem `""` quando o treinamento não tem. |
| `atleta` | Antes da execução, o atleta da época em que o plano gerou o treino; depois, quem registrou a execução. `null` se não houver. |
| `exercicios[].posicao` | De 1 a n (o "1/n" do carrossel). Um exercício repetido aparece em cada posição. |
| `exercicios[].codigo` | Abre o detalhe do exercício (`getExercise`, botão "Ver detalhes") e identifica a posição no envio da execução. |
| `exercicios[].realizacao` | `PENDENTE` até a execução; depois, `REALIZADO` ou `NAO_REALIZADO`. |
| `exercicios[].materiais`, `midias` | "Materiais necessários" (da versão **atual** do exercício; a cópia não os guarda) e "Mídias auxiliares", buscadas no Storage pelo código do exercício: fotos em `/fotos/exercicios/<codigo>_<n>.jpg` ou `.png` (n de 1 a 10) e vídeos em `/videos/exercicios/<codigo>_<n>.mp4` (n de 1 a 3), em ordem de n. Valem também arquivos postos direto no Storage com esse nome; outros nomes são ignorados. |
| `exercicios[].midias.semMidias` | `true` quando o exercício não tem nenhuma foto nem vídeo: mostre um aviso (por exemplo, "Não há mídias de demonstração") no lugar do carrossel. Com fotos e sem vídeo, vem `false` e mostra só as fotos. |
| URLs das mídias | Valem 15 minutos, menos que muitos treinos. Para renovar durante a execução, chame `getTrainingRecord` de novo: as marcações ficam no app até o envio, então nada se perde. |
| `execucao` | `null` até o atleta registrar. `dataExecucao` vem `null` só em registro `REALIZADO` ou `PARCIAL` antigo, gravado sem a data. Em `NAO_REALIZADO`, `duracaoEfetiva` e `percepcaoDesempenho` vêm `null`. `dificuldades` vem `""` e `observacoes`, `[]`, quando não informadas. `exerciciosRealizados` e `exerciciosNaoRealizados` são os "Exercícios concluídos" e "Exercícios incompletos". |
| `feedback` | `null` até o feedback. `data` é a "Data do registro", em UTC. |
| `permissoes.podeRegistrarExecucao` | Botão "Iniciar treino". `false` mostra "Ver treino" ou "Treino finalizado". |
| `permissoes.podeRegistrarFeedback` | Botão "Escrever feedback". Para o responsável, use "Acessar feedback" com o aviso "Nenhum feedback registrado" quando `feedback` for `null`. |

## registerTrainingExecution

Exige login. Envio único, no fim do treino ("Submeter registro"), depois da
confirmação "Tem certeza que deseja finalizar o treino?".

```json
{
  "registroId": "66e1a0c2f1b2c3d4e5f6f103",
  "exercicios": [
    { "codigo": "17", "realizacao": "REALIZADO" },
    { "codigo": "23", "realizacao": "NAO_REALIZADO", "observacao": "Cavalo cansado" }
  ],
  "duracaoEfetiva": 50,
  "percepcaoDesempenho": 8,
  "dificuldades": "Complicações quando está na mão esquerda",
  "observacoes": ["Cavalo mais agitado no início"]
}
```

| Campo | Regra |
| --- | --- |
| `exercicios` | Obrigatório. Um item por exercício do treino, na ordem de `getTrainingRecord` (de 1 a 50). `codigo` é o `exercicios[].codigo` daquela posição, como string; `realizacao` é `REALIZADO` (exercício finalizado) ou `NAO_REALIZADO`; `observacao` é opcional, até 500 caracteres. |
| `duracaoEfetiva` | "Tempo total", em minutos inteiros de 1 a 480. Arredonde o cronômetro para cima (menos de um minuto conta 1) e deixe o atleta conferir antes de enviar. Obrigatório quando algum exercício foi realizado; recusado quando nenhum foi. |
| `percepcaoDesempenho` | Nota inteira de 1 a 10 (10 é o desempenho máximo). Mesma regra da duração. |
| `dificuldades` | "Dificuldades encontradas", opcional, até 1000 caracteres. Texto em branco conta como ausente. Preenchido, é recusado quando nenhum exercício foi realizado. |
| `observacoes` | "Observações", opcional, até 30 textos de até 500 caracteres (quebre o texto digitado em linhas; linhas em branco são descartadas). Aceito em qualquer situação; em `NAO_REALIZADO`, é o motivo. |

A situação gravada sai das marcações: todos realizados, `REALIZADO`; parte,
`PARCIAL`; nenhum, `NAO_REALIZADO`. O app **não** envia a situação, a data
nem o atleta: o servidor grava hoje e a conta de quem envia. Se o treinador
mudar os exercícios do treino enquanto o atleta treina, o envio é recusado
e o atleta precisa abrir o treino de novo.

Resposta: a mesma de `getTrainingRecord`, já com a execução.

## registerTrainingFeedback

Exige login. Depois da revisão do formulário ("Registrar feedback").

```json
{
  "registroId": "66e1a0c2f1b2c3d4e5f6f103",
  "comentario": "Boa resposta às transições.",
  "dificuldadesIdentificadas": ["Perda de equilíbrio na mão esquerda."],
  "orientacoes": ["Reforçar o trabalho bilateral."]
}
```

| Campo | Regra |
| --- | --- |
| `comentario` | "Comentários sobre a execução", obrigatório, de 1 a 1000 caracteres. |
| `dificuldadesIdentificadas`, `orientacoes` | "Dificuldades identificadas" e "Correções e orientações", opcionais (ausente ou `null` vira `[]`), até 30 textos de até 500 caracteres cada; linhas em branco são descartadas. |

Aceito em treino `REALIZADO` ou `PARCIAL` (inclusive registro antigo sem
`dataExecucao`) ou `NAO_REALIZADO` registrado pelo atleta, e ainda sem
feedback. Um `NAO_REALIZADO` gravado pelo encerramento
ou pelo cancelamento do plano não aceita feedback. O servidor grava a data e
a hora do envio.

Resposta: a mesma de `getTrainingRecord`, já com o feedback.

## listPendingFeedbacks

Exige login de **treinador**. Pedido vazio (`{}`); qualquer campo é
recusado.

```json
{
  "execucoes": [
    {
      "id": "66e1a0c2f1b2c3d4e5f6f103",
      "data": "2026-11-21",
      "status": "PARCIAL",
      "duracaoEfetiva": 50,
      "nomeTreinamento": "Trabalho de transições",
      "nomeCavalo": "Trovão",
      "nomeAtleta": "Bruno Lima"
    }
  ],
  "possuiMais": false
}
```

Até 50 treinos dos planos do treinador, com relato do atleta e sem
feedback, da data de execução mais recente para a mais antiga; no mesmo dia,
a execução enviada por último vem primeiro. `data` é a data de execução
(`null` em registro antigo sem ela, que vem por último); `duracaoEfetiva` vem `null` em `NAO_REALIZADO`;
`nomeAtleta`, `null` se não houver; `possuiMais` é `true` quando há mais de
50. Cada `id` abre `getTrainingRecord`.

## Erros

| Situação | Código | Mensagem |
| --- | --- | --- |
| Sem login | `unauthenticated` | — |
| Conta inativa | `permission-denied` | "Conta inativa ou inexistente." |
| `registroId` inválido | `invalid-argument` | "Identificador do treino inválido." |
| Campo desconhecido | `invalid-argument` | "O campo 'x' não pode ser editado." |
| Treino inexistente ou sem acesso | `not-found` | "Treino não encontrado." |
| `exercicios` ausente, vazio ou com mais de 50 | `invalid-argument` | "Informe a situação de cada exercício do treino." |
| Item de `exercicios` inválido | `invalid-argument` | "Exercício N: código inválido.", "Exercício N: a situação deve ser REALIZADO ou NAO_REALIZADO." ou "Exercício N: a observação deve ter até 500 caracteres." |
| Duração | `invalid-argument` | "A duração efetiva deve ser um número inteiro de 1 a 480 minutos." |
| Percepção | `invalid-argument` | "A percepção de desempenho deve ser um número inteiro de 1 a 10." |
| Dificuldades | `invalid-argument` | "As dificuldades devem ter até 1000 caracteres." |
| Não realizado com duração, percepção ou dificuldades | `invalid-argument` | "Um treino não realizado não tem duração efetiva, percepção de desempenho nem dificuldades." |
| Listas de textos | `invalid-argument` | "Observações: informe no máximo 30 itens.", "Cada observação deve ter até 500 caracteres." (o mesmo para dificuldades identificadas e orientações) |
| Comentário | `invalid-argument` | "O comentário deve ter entre 1 e 1000 caracteres." |
| Execução por quem não é o atleta | `permission-denied` | "Apenas o atleta do cavalo pode registrar a execução do treino." |
| Treino cancelado | `failed-precondition` | "Este treino foi cancelado." |
| Treino de outro dia | `failed-precondition` | "Só é possível registrar a execução do treino de hoje." |
| Execução já registrada | `failed-precondition` | "A execução deste treino já foi registrada." |
| Exercícios mudaram | `failed-precondition` | "Os exercícios deste treino mudaram. Abra o treino de novo para registrar a execução." |
| Feedback por quem não é o treinador do plano | `permission-denied` | "Apenas o treinador do plano pode registrar o feedback." |
| Feedback já registrado | `failed-precondition` | "Este treino já possui um feedback." |
| Treino sem relato do atleta | `failed-precondition` | "O feedback só pode ser registrado depois da execução do treino." |
| `listPendingFeedbacks` por responsável | `permission-denied` | "Acesso não permitido para este perfil." |

## Dados gravados e divergências do DD

- `registros_treino.percepcaoDesempenho` é um número de 1 a 10 (o DD previa
  texto). A tela "Treino concluído" do Figma e a maquete do feedback mostram
  texto livre e precisam virar uma escala de 1 a 10.
- `dataExecucao` também é gravada quando o atleta registra `NAO_REALIZADO`:
  é ela que separa o relato do atleta do `NAO_REALIZADO` gravado pelo
  encerramento ou pelo cancelamento do plano.
- As dificuldades vão para o campo `dificuldade` (singular, como no DD).
- A execução troca o `responsavel` do treino por quem a registrou.
- Nada mais muda: agenda, home, perfil do cavalo e dashboard passam a
  mostrar execuções e feedbacks sem mudar de formato.
- Mídias auxiliares: o servidor não depende de `exercicios.imagens` e
  `exercicios.videos` para o treino; ele lista o Storage pelo código do
  exercício. Um arquivo que não pode ser lido é pulado, com um aviso no log
  da function, e o treino abre mesmo com o Storage fora do ar.
