# Dicionário de Dados: Projeto HorseLife

Este dicionário descreve os dados do MVP do HorseLife, aplicativo que permite ao treinador planejar e acompanhar remotamente o treinamento de cavalos, enquanto o responsável pelo animal executa e registra as sessões.

## 1. Histórico de versões (ou revisões)

| Data | Autor | Versão | Comentários |
| --- | --- | --- | --- |
| 23/11/2026 | Davi Froza e Miguel Castro | 1.0.0 | Correção de inconsistências menores. Entrega da versão definitiva |
| 09/10/2026 | Miguel Castro e Noemi Kayama | 1.0.0-alfa7 | Ajuste no código do cavalo. |
| 01/10/2026 | Miguel Castro e Noemi Kayama | 1.0.0-alfa6 | Acréscimo do campo código nas coleções e adequação terminológica de status para situação cadastral e situação profissional. |
| 30/09/2026 | Davi Alves Froza, Miguel Castro e Noemi Kayama | 1.0.0-alfa5 | Refatoração das seções 4 e 5 com base nas modificações da versão 1.0.0-alfa4. |
| 29/09/2026 | Davi Froza, Miguel Castro e Noemi Kayama | 1.0.0-alfa4 | Refatoração das entidades. Exclusão de escalas (Antigo 3.3). |
| 24/09/2026 | Davi Alves Froza, Miguel Castro | 1.0.0-alfa3 | Revisão geral. |
| 23/09/2026 | Davi Alves Froza, Miguel Castro | 1.0.0-alfa2 | Refinamento das seções 4 e 5. |
| 22/09/2026 | Davi Alves Froza, Miguel Castro | 1.0.0-alfa1 | Versão inicial. Título e estrutura do documento, citação das entidades e suas descrições. |

## 2. Entidades e atributos conceituais

As entidades que o MVP do HorseLife deverá contemplar, seus atributos, tipos conceituais, características e comentários sobre cada atributo, com exemplos aceitos e não aceitos.

### 2.1. Responsável

Responsável é o responsável pelo cavalo na plataforma: cavaleiro, amazona ou proprietário. É quem consulta os planos atribuídos ao cavalo, executa os treinamentos e registra sua realização.

#### Atributos de Responsável

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| codigo | Código | Sim | Simples | 1, 67, 123 | vazio, nulo | Código interno do responsável. |
| nome | Texto alfanumérico | Sim | Simples | José Papoi, Deoclécio Silva | "", " ", "A" | Nome completo do responsável. Mínimo de 3 caracteres. |
| email | Texto | Sim | Simples | jose.papoi@example.com | jose@, "", e-mail já cadastrado | Usado no login. Deve ser único na plataforma, inclusive em relação aos e-mails de treinadores. Armazenado em minúsculas. |
| senha | Texto | Sim | Simples | Qualquer texto com 8 ou mais caracteres | "abc123" (menos de 8 caracteres), "" | Gerenciada pelo Firebase Authentication. Não é armazenada no MongoDB. |
| situacaoCadastral | Texto Enumerado | Sim | Simples | ATIVO, INATIVO | Qualquer valor fora da lista | Exclusão lógica. Responsável inativo não autentica, mas seu histórico é preservado. |
| cavalos | Cavalo | Não | Relacionamento | Trovão, atleta e proprietario | cavalo sem tipo de responsabilidade | (N:N) Um responsável pode estar relacionado a n cavalos, podendo possuir tipos de responsabilidade distintos entre si. |
| modalidades | Modalidade | Não | Multivalorado e Composto (MC) | Hipismo | Modalidade nula | Informações sobre as modalidades do responsável |

### 2.2. Treinador

Treinador é o profissional que avalia o cavalo, elabora os planos de treinamento, cadastra exercícios e treinamentos e dá feedback sobre as sessões executadas. Além dos dados de acesso, mantém informações básicas de perfil profissional, incluindo as regiões em que atende.

#### Atributos de Treinador

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| codigo | Código | Sim | Simples | 1, 67, 123 | vazio, nulo | Código interno do treinador. |
| nome | Texto alfanumérico | Sim | Simples | Bruno Bohnen Mit, Naomi Mehl | "", " ", "A" | Nome completo do treinador. Mínimo de 3 caracteres. |
| email | Texto | Sim | Simples | bruno.bohnen@example.com | bruno@, "", e-mail já cadastrado | Usado no login. Deve ser único na plataforma, inclusive em relação aos e-mails de responsáveis. Armazenado em minúsculas. |
| senha | Texto | Sim | Simples | Qualquer texto com 8 ou mais caracteres | "abc123" (menos de 8 caracteres), "" | Gerenciada pelo Firebase Authentication. Não é armazenada no MongoDB. |
| situacaoProfissional | Texto enumerado | Sim | Simples | DISPONIVEL, AFASTADO, INDISPONIVEL, INATIVO | Qualquer valor fora da lista | Exclusão lógica. Treinador inativo não autentica, mas seu histórico é preservado. |
| modalidades | Texto | Não | Multivalorado (M) | Adestramento, Salto, Enduro | lista com item vazio | Informativo. Não há busca de profissionais no MVP. |
| experiencias | Documento PDF | Não | Simples | Arquivo PDF estruturado pelo treinador | lista com item vazio | Um único PDF por treinador; um novo envio substitui o anterior. Guardado como caminho (texto) ou nulo. |
| certificacoes | Documento PDF | Não | Multivalorado (M) | Arquivo PDF estruturado pelo treinador | lista com item vazio | Texto informativo. |
| regioesAtendimento | Região de atendimento | Não | Composto multivalorado (MC) | SP, Campinas, Região de Barão Geraldo | região sem estado ou sem cidade | Informativo. Estrutura em 3.4. |
| cavalos | Cavalo | Não | Relacionamento | Trovão, Estrela do Sul | cavalo sem vínculo com o treinador | Cavalos que o treinador acompanha |
| clientes | Resposável | Não | Relacionamento | Maria Oliveira | Responsável sem cavalo acompanhado pelo treinador | Clientes do treinador (N:N). Derivado dos responsáveis dos cavalos que ele acompanha. Um responsável deixa de ser cliente quando nenhum de seus cavalos é acompanhado pelo treinador. |

### 2.3. Cavalo

Cavalo é o animal sobre o qual todo o acompanhamento gira. Avaliações, planos, registros de treino e feedbacks são organizados em torno dele, o que evita registros dispersos e permite construir seu histórico ao longo do tempo. O cavalo pertence a um responsável e pode estar associado a um único treinador. As informações de saúde têm caráter informativo, sem função de diagnóstico. Um cavalo só pode ter um plano de treinamento ativo por vez.

#### Atributos de Cavalo

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| codigo | Código | Sim | Simples | 012345678943210 | vazio, nulo, “abcdef012345678”, | Código do microchip do cavalo. Verificado através do servidor. Precisa ter 15 dígitos numéricos. Salvo como String. |
| nome | Texto alfanumérico | Sim | Simples | Trovão, Sol, Estrela do Sul | "", " " | Nome do cavalo. Mínimo de 2 caracteres. |
| dataNascimento | Data | Sim | Simples | 2016-04-10 | data futura, data impossível | A idade não é armazenada: é calculada a partir desta data. Se o dia ou o mês forem desconhecidos, usar uma estimativa. |
| raca | Texto | Sim | Simples | BH, Lusitano, SRD | "" | Aceitar SRD (sem raça definida). |
| pelagem | Texto | Sim | Simples | Palomino, Tordillo | "" | Aceitar SPD (sem pelagem definida). |
| sexo | Texto enumerado | Sim | Simples | MACHO, FEMEA | qualquer valor fora da lista | Sexo do cavalo. |
| imagens | Arquivo ou URL | Não | Multivalorado (M) | /fotos/cavalos/50_1.jpg | caminho vazio | Referência aos arquivos, que podem ficar fora do banco. |
| modalidade | Modalidade | Não | Simples | Salto, Adestramento, Enduro | "" quando informado | Modalidade principal praticada pelo cavalo. |
| limitacoesFisicas | Texto | Não | Multivalorado (M) | Sensibilidade no casco posterior esquerdo | lista com item vazio | Registro informativo, sem diagnóstico. |
| observacoesSaude | Texto | Não | Multivalorado (M) | Vacinas em dia | lista com item vazio | Registro informativo, sem diagnóstico. |
| historicoLesoes | Registro de lesão | Não | Composto multivalorado (MC) | 2025-03-12, Distensão leve, repouso de 3 semanas | lesão sem data ou sem descrição | Estrutura em 3.3. |
| situacaoCadastral | Texto Enumerado | Sim | Simples | ATIVO, INATIVO | Qualquer valor fora da lista | Exclusão lógica. |
| proprietário | Responsável | Sim | Relacionamento | Maria Oliveira | nulo | Responsável pelo cavalo (N:N). Um cavalo tem um N responsáveis . |
| atleta | Responsável | Não | Relacionamento | Deoclecio, Zezin | nulo | Responsável que executa os treinos (N:1). Pode coincidir com o proprietário. Opcional: pode ser desvinculado, e o cavalo fica sem atleta. |
| treinador | Treinador | Não | Relacionamento | fjkawal9201, Carlos Mendes | segundo treinador para o mesmo cavalo | Um cavalo pode ter mais de um treinador. |
| planoAtual | Plano de Treinamento | Não | Relacionamento | Condicionamento para percursos de 1,00 m | plano com status diferente de ATIVO, plano de outro cavalo | Plano em andamento do cavalo (0..1). Existe apenas enquanto houver um plano ATIVO. Derivado de Plano.cavalo e Plano.status. |
| avaliacoes | Avaliação | Não | Relacionamento | Avaliação de 05/09/2026 | avaliação de outro cavalo | Avaliações do cavalo (1:N). Inverso de Avaliação.cavalo. |

### 2.4. Avaliação

Avaliação é o registro que o treinador faz da situação do cavalo antes de elaborar o plano de treinamento. Ela justifica e orienta o plano, que deixa de ser uma sequência genérica de exercícios. Como possui data e autor, permite comparar a evolução do cavalo ao longo do tempo. Tem caráter esportivo e não substitui avaliação veterinária.

Uma avaliação já vinculada a um plano (como avaliação inicial) não pode ser editada. Correções são feitas criando uma nova avaliação, para preservar o histórico e a cópia guardada no plano.

#### Atributos de Avaliação

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| codigo | Código | Sim | Simples | 1, 67, 123 | vazio, nulo | Código interno da avaliação. |
| cavalo | Cavalo | Sim | Relacionamento | dsgsgd0f90a910, Trovão | nulo | Cavalo avaliado (N:1). |
| treinador | Treinador | Sim | Relacionamento | Carlos Mendes | nulo, treinador não vinculado ao cavalo | Autor da avaliação (N:1). Deve ser o treinador vinculado ao cavalo. |
| data | Data | Sim | Simples | 2026-09-05 | data futura, data impossível | Data em que o cavalo foi avaliado. |
| condicionamentoFisicoObservado | Texto | Sim | Simples | Fôlego regular após 20 minutos de trabalho | "" | Descrição livre do condicionamento físico observado. |
| limitacoes | Texto | Não | Texto livre | Evitar terreno duro | “” quando informado | Limitações observadas na data da avaliação. |
| dificuldades | Texto | Não | Texto livre | Perde ritmo após a segunda linha de obstáculos | “” quando informado | Dificuldades observadas na data da avaliação. |
| modalidades | Modalidade | Não | Multivalorado (M) | Salto | lista com item vazio | Modalidades praticadas na data da avaliação. Pode diferir da modalidade principal do cavalo. |
| observacoes | Texto | Não | Multivalorado (M) | Boa disposição, reage bem a comandos de perna | lista com item vazio | Observações gerais do treinador. |

### 2.5. Exercício

Exercício é uma atividade que compõe os treinamentos. Pode ser cadastrado pela plataforma (catálogo público) ou por um treinador, que pode mantê-lo exclusivo ou torná-lo público. Exercícios podem ser editados, mas os treinamentos, planos e registros que os utilizam guardam uma cópia (snapshot) dos dados do momento em que foram incluídos (ver 3.5).

#### Atributos de Exercício

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| codigo | Código | Sim | Simples | 1, 67, 123 | vazio, nulo | Código interno do exercício. |
| nome | Texto alfanumérico | Sim | Simples | Transições trote-galope, Aquecimento ao passo | "", " " | Nome do exercício. Mínimo de 3 caracteres. |
| descricao | Texto | Sim | Simples | Alternar trote e galope em intervalos definidos | "" | Explica o que é o exercício. |
| orientacoes | Texto | Não | Multivalorado (M) | Manter contato leve com as rédeas | lista com item vazio | Orientações de execução. |
| duracaoPadraoMinutos | Número inteiro | Sim | Simples | 10, 30 | 0, -5, "30 minutos" | Duração sugerida, em minutos. |
| materiais | Texto | Sim | Multivalorado Composto (MC) | Vara, 3; Cavalete, 2 | Valores nulos, quantidades de material menores que 0. | Materiais necessários para realização do exercício, com sua descrição e quantidade de cada material |
| privacidade | Texto enumerado | Sim | Simples | ESPECIFICO, GENERICO | qualquer valor fora da lista | ESPECIFICO: exercício feito para um cavalo, guardado em cavalo (obrigatório, só cavalos vinculados ao treinador). GENERICO: exercício do acervo do treinador, sem cavalo. |
| cavalo | Cavalo | Obrigatórios para exercícios específicos | Relacionamento | _id, código e nome do cavalo | Dados de um cavalo inexistente durante o cadastro | Representa o cavalo vinculado exclusivamente ao exerćicio |
| ativo | Booleano | Sim | Simples | true, false | sim, não | Exclusão lógica. Exercícios modificados ainda devem manter sua versão obsoleta. |
| imagens | URL | Não | Multivalorado (M) | /imagens/exercicios/50_1.jpg | caminho vazio | Referência dos arquivos no Firebase Storage. Os arquivos ficam fora do banco. |
| videos | URL | Não | Multivalorado (M) | /videos/exercicios/50_1.mp4 | caminho vazio | Referência dos arquivos no Firebase Storage. Os arquivos ficam fora do banco. |
| cadastrante | Texto enumerado | Sim | Simples | PLATAFORMA, TREINADOR | qualquer valor fora da lista | Origem do cadastro do exercício. |
| treinador | Treinador | Condicional | Relacionamento | Carlos Mendes, _id | preenchido quando cadastrante for PLATAFORMA | Obrigatório quando cadastrante for TREINADOR (N:1). Quando for PLATAFORMA, fica vazio e privacidade deve ser GENERICO. |

### 2.6. Treinamento

Treinamento é uma sessão de treino reutilizável, criada e mantida pelo treinador: um conjunto de exercícios com sua duração estimada. O mesmo treinamento pode ser usado várias vezes, no mesmo plano ou em planos diferentes. Cada treinamento é exclusivo do treinador que o criou. Como pode ser editado, os planos e registros que o utilizam guardam uma cópia (snapshot) dos dados do momento em que foi incluído, então edições posteriores não alteram planos já criados.

#### Atributos de Treinamento

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| codigo | Código | Sim | Simples | 1, 67, 123 | vazio, nulo | Código interno do treinamento. |
| titulo | Texto alfanumérico | Sim | Simples | Trabalho de transições | "", " " | Nome curto para identificar o treinamento. Mínimo de 3 caracteres. |
| descricao | Texto | Não | Simples | Sessão focada em equilíbrio nas transições de andamento | "" quando informado | Explica o objetivo da sessão. |
| orientacoes | Texto | Não | Multivalorado (M) | Encerrar com 5 minutos de passo | lista com item vazio | Orientações gerais para a sessão. |
| duracaoEstimadaMinutos | Número inteiro | Sim | Simples | 45, 90 | 0, -10, "3 horas" | Duração da sessão, em minutos. Pode diferir da soma dos exercícios (descansos, deslocamentos). |
| treinador | Treinador | Sim | Relacionamento | Carlos Mendes | nulo | Autor e dono do treinamento (N:1). |
| exercicios | Exercício em uso | Sim | Composto multivalorado (MC) | Lista com ao menos um item | lista vazia | Cada item liga o treinamento a um exercício e guarda uma cópia dos dados dele. Estrutura em 3.5. A ordem da lista é a ordem de execução. |

### 2.7. Plano de Treinamento

Plano de Treinamento é a principal funcionalidade do MVP. Converte as orientações do treinador em uma rotina estruturada e acessível ao responsável, permitindo que o treinamento continue mesmo sem a presença do profissional. O plano tem um objetivo e um planejamento semanal: uma lista de itens, cada um com um treinamento e os dias da semana em que ele se repete entre dataInicio e dataFim. Um cavalo só pode ter um plano ATIVO por vez.

#### Atributos de Plano de Treinamento

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| codigo | Código | Sim | Simples | 1, 67, 123 | vazio, nulo | Código interno do plano. |
| titulo | Texto alfanumérico | Sim | Simples | Condicionamento para percursos de 1,00 m | "", " ", "A" | Nome curto do plano, usado para identificá-lo em listagens. Mínimo de 3 caracteres. |
| objetivo | Texto | Sim | Simples | Ganhar condicionamento para percursos de 1,00 m | "" | Objetivo do plano. Difere do objetivo geral do cavalo (2.3). |
| cavalo | Cavalo | Sim | Relacionamento | Trovão | nulo, cavalo sem treinador | Cavalo que executa o plano (N:1). |
| treinador | Treinador | Sim | Relacionamento | Carlos Mendes | nulo, treinador diferente do vinculado ao cavalo | Autor do plano (N:1). |
| avaliacaoInicial | Avaliação | Não | Relacionamento | Avaliação de 05/09/2026 do cavalo Trovão | avaliação de outro cavalo | Avaliação que originou o plano (N:1). Opcional: o plano pode ser criado sem avaliação. Os dados da avaliação são copiados para o plano. Depois de vinculada, a avaliação não pode ser editada (2.4). |
| status | Texto enumerado | Sim | Simples | RASCUNHO, ATIVO, CONCLUIDO, CANCELADO | qualquer valor fora da lista | O plano já é criado ATIVO; RASCUNHO fica reservado e não é gerado no MVP. ATIVO: em execução (no máximo um por cavalo). CONCLUIDO: ATIVO cuja dataFim já passou; aparece assim nas consultas e é gravado quando um novo plano é criado para o cavalo. CANCELADO: encerrado pelo treinador. |
| dataInicio | Data | Sim | Simples | 2026-09-07 | vazio, data impossível | Início do plano. No cadastro, deve ser hoje ou uma data futura. |
| dataFim | Data | Sim | Simples | 2026-10-04 | data anterior ao início | Fim do plano. Obrigatório; o plano dura no máximo 12 meses. |
| planejamento | Item do planejamento | Sim | Composto multivalorado (MC) | Lista com ao menos um item | lista vazia, códigos de item repetidos | Estrutura em 3.6. Cada item é um treinamento e os dias da semana em que ele se repete; cada data resultante gera um registro de treino. |

### 2.8. Registro de Treino

Registro de Treino representa a execução de um item do planejamento, com uma sessão por registro. É criado antes da execução, na criação do plano, com status PLANEJADO, um para cada data de cada item. O responsável o atualiza depois para registrar a realização, e o treinador o consulta para dar feedback. Sem essa entidade, o treinador conheceria apenas o planejamento, e não a execução. Os registros são a base do dashboard. O cavalo, o responsável e o treinador de um registro coincidem com os do plano.

#### Atributos de Registro de Treino

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| codigo | Código | Sim | Simples | 1, 67, 123 | vazio, nulo | Código interno do registro. |
| plano | Plano de Treinamento | Sim | Relacionamento | Condicionamento para percursos de 1,00 m | nulo | Plano ao qual o registro pertence (N:1). |
| itemPlanejamento | Código | Sim | Simples | 1, 2, 3 | vazio, nulo, item inexistente no plano | Código do item do planejamento, dentro do plano, que originou o registro. Liga o registro à ocorrência exata do treinamento. |
| responsável | Responsável | Não | Relacionamento | idjfiehfurshfuhrsuh, José Deoclécio | nulo, responsável diferente do responsável pelo cavalo | Atleta que registra a execução (N:1). Copiado do atleta do cavalo na geração do registro; ausente quando o cavalo não tem atleta e gravado quando a execução é registrada. |
| cavalo | Cavalo | Sim | Relacionamento | Trovão | nulo, cavalo diferente do plano | Cavalo que treina (N:1). Deve coincidir com o cavalo do plano. |
| treinador | Treinador | Sim | Relacionamento | Carlos Mendes | nulo, treinador diferente do plano | Treinador do plano (N:1). |
| semana | Número inteiro | Sim | Simples | 1, 2 | 0, -1 | Semana do plano em que o treinamento foi planejado. Copiada do item do planejamento. |
| status | Texto enumerado | Sim | Simples | PLANEJADO, REALIZADO, PARCIAL, NAO_REALIZADO, CANCELADO | qualquer valor fora da lista | Nasce como PLANEJADO. Ao registrar a execução, muda para REALIZADO, PARCIAL ou NAO_REALIZADO, conforme as marcações dos exercícios (ver 5.2). No cancelamento do plano, os PLANEJADO de hoje em diante passam para CANCELADO e os de dias anteriores para NAO_REALIZADO; na conclusão, os PLANEJADO restantes passam para NAO_REALIZADO. Um PLANEJADO de dia anterior é exibido como NAO_REALIZADO. |
| dataPlanejada | Data | Sim | Simples | 2026-09-08 | vazio, data impossível | Data gerada a partir dos diasSemana do item, entre dataInicio e dataFim do plano. Permite identificar treinos atrasados. |
| dataExecucao | Data | Condicional | Simples | 2026-09-08 | data futura | Gravada sempre que o atleta registra a execução, inclusive em NAO_REALIZADO. Ausente no NAO_REALIZADO gerado pelo cancelamento ou encerramento do plano. |
| duracaoEfetivaMinutos | Número inteiro | Condicional | Simples | 40, 55 | 0, -10, "40 min" | Obrigatória quando status for REALIZADO ou PARCIAL. |
| percepcaoDesempenho | Número inteiro | Condicional | Simples | 1, 7, 10 | 0, 11, 7.5, "bom" | Nota do atleta para o desempenho do cavalo, inteiro de 1 a 10. Obrigatória quando status for REALIZADO ou PARCIAL e ausente em NAO_REALIZADO. |
| dificuldade | Texto | Não | Simples | Complicações quando está na mão esquerda | texto em branco, texto com mais de 1000 caracteres | Dificuldade percebida pelo responsável na sessão. |
| observacoes | Texto | Não | Multivalorado (M) | Cavalo mais agitado no início | lista com item vazio | Observações do responsável sobre o comportamento e o rendimento do cavalo. |
| treinamento | Cópia do treinamento | Sim | Composto (C) | 42, Trabalho de transições, 45 | treinamento diferente do item do planejamento | Cópia dos dados do treinamento no momento da geração do registro, sem os exercícios (que ficam em exercicios). Estrutura em 3.7. |
| exercicios | Exercício Realizados | Sim | Composto multivalorado (MC) | Lista com ao menos um item | lista vazia | Exercícios do treinamento na geração do registro, completude e observações do responsável |
| feedback | Feedback | Não | Composto (C) | { data: 2026-09-08 20:10:00, comentario: Boa evolução no equilíbrio nas transições } | feedback em registro sem execução registrada pelo atleta | Resposta do treinador à sessão. Único por registro. Preenchido após a execução. Estrutura em 3.8. |

### 2.9. Dashboard de evolução (dados derivados)

O dashboard básico do MVP não possui entidade própria. Seus indicadores são calculados a partir dos registros de treino (2.8), sem armazenamento adicional. Não há análises avançadas, inteligência artificial ou relatórios complexos nesta versão.

| Indicador | Cálculo | Fonte |
| --- | --- | --- |
| Treinos realizados | Quantidade de registros com status REALIZADO ou PARCIAL | registro.status |
| Percentual de cumprimento | Média, entre os registros REALIZADO e PARCIAL, da razão duracaoEfetivaMinutos ÷ treinamento.duracaoEstimadaMinutos, limitada a 100% | registro.duracaoEfetivaMinutos, registro.treinamento.duracaoEstimadaMinutos |
| Frequência | (REALIZADO + PARCIAL) ÷ registros previstos no período até hoje, excluindo CANCELADO | registro.status, registro.dataPlanejada |
| Exercícios cumpridos | Fora do MVP: a realização dos exercícios não entra em métricas (ver 5.2) | registro.exercicios.realizacao |
| Registros recentes | Últimos registros executados, em ordem decrescente de dataExecucao | registro.dataExecucao |
| Feedbacks recebidos | Últimos feedbacks, em ordem decrescente de feedback.data | registro.feedback |

### 2.10. Modalidade

Modalidades de esportes

#### Atributos de Modalidade

| Atributo / Dado | Tipo conceitual | Obrigatório | Característica | Ex. aceitos | Ex. não aceitos | Comentários |
| --- | --- | --- | --- | --- | --- | --- |
| codigo | Código | Sim | Simples | 1, 67, 123 | vazio, nulo | Código interno da modalidade. |
| nome | Texto | Sim | Simples | Hipismo | "", " ", "A" | Nome da modalidade. |
| descrição | Texto alfanumérico | Sim | Simples | Hipismo é a modalidade da arte de montar a cavalo que compreende todas as práticas desportivas que envolvam este animal. | "", " ", "A" | Descrição da modalidade. |

## 3. Tipos especiais, compostos ou específicos

Neste projeto existem tipos compostos, multivalorados e reutilizáveis. Como padrão de documentação, há uma definição norteadora:

### 3.1. Padrões de atributos especiais

| Código | Significado | Uso no dicionário |
| --- | --- | --- |
| C | Composto | Usado quando um atributo possui partes internas. |
| M | Multivalorado | Usado quando um atributo pode ter vários valores. |
| MC | Multivalorado e composto | Usado quando há uma lista de estruturas compostas. |

Atributos com característica "Relacionamento" têm como tipo conceitual outra entidade do dicionário. A cardinalidade (1:1, N:1, 1:N, N:N) é indicada no comentário.

### 3.3. Registro de lesão

Estrutura composta usada em Cavalo.historicoLesoes. Além de data e descricao, aceita prescricao (texto, opcional): orientação recebida para a lesão, também sem caráter de diagnóstico.

| Atributo / Dado | Tipo conceitual | Obrigatório | Comentários |
| --- | --- | --- | --- |
| data | Data | Sim | Data da lesão. Não pode ser futura. |
| descricao | Texto | Sim | Descrição informativa da lesão. Não constitui diagnóstico. |

### 3.4. Região de atendimento

Estrutura composta usada em Treinador.regioesAtendimento.

| Atributo / Dado | Tipo conceitual | Obrigatório | Comentários |
| --- | --- | --- | --- |
| estado | Texto | Sim | Sigla da unidade federativa, com 2 letras maiúsculas (ex.: SP, MG). Valores como "" ou "São Paulo" não são aceitos. |
| cidade | Texto | Sim | Nome da cidade atendida. |
| complemento | Texto | Não | Detalhe da abrangência, como bairro ou região (ex.: Região de Barão Geraldo). |

### 3.5. Exercício em uso

Estrutura composta que representa um exercício dentro de um treinamento ou de um registro de treino. Mantém a ligação com o exercício de origem e guarda uma cópia (snapshot) dos dados dele no momento da inclusão. Edições posteriores no exercício não alteram esta cópia. Usada em Treinamento.exercicios.

| Atributo / Dado | Tipo conceitual | Obrigatório | Comentários |
| --- | --- | --- | --- |
| exercicio | Exercício | Sim | Relacionamento (N:1) com o exercício de origem, mantido para rastreabilidade. Guarda o _id e o codigo do exercício de origem. |
| nome | Texto alfanumérico | Sim | Cópia do nome do exercício no momento da inclusão. |
| descricao | Texto | Sim | Cópia da descrição no momento da inclusão. |
| orientacoes | Texto (M) | Não | Cópia das orientações no momento da inclusão. |
| duracaoPadraoMinutos | Número inteiro | Sim | Duração deste uso, em minutos. Inicia com a duração padrão do exercício e pode ser ajustada pelo treinador. |

### 3.6. Item do planejamento

Estrutura composta usada em Plano de Treinamento.planejamento. Cada item associa um treinamento aos dias da semana em que ele é feito, de dataInicio a dataFim. Cada dia da semana tem no máximo um treinamento, e cada treinamento aparece em um único item ativo, com todos os seus dias.

| Atributo / Dado | Tipo conceitual | Obrigatório | Comentários |
| --- | --- | --- | --- |
| codigo | Código | Sim | Identifica o item dentro do plano (1, 2, 3...). Único no plano. É referenciado pelo campo itemPlanejamento do Registro de Treino. |
| ativo | Booleano | Sim | Indica se o item continua em uso. Na edição do plano, itens removidos ficam com ativo = false, preservando a ligação com os registros já gerados, e não geram novos registros. |
| diasSemana | Texto enumerado (M) | Sim | Dias da semana em que o treinamento é feito (SEGUNDA, TERCA, QUARTA, QUINTA, SEXTA, SABADO, DOMINGO). Ao menos um. Cada data entre dataInicio e dataFim que cai nesses dias gera um registro de treino. |
| treinamento | Treinamento | Sim | Relacionamento (N:1) com o treinamento utilizado. Os dados dele, incluindo os exercícios em uso, são copiados para o item no momento da inclusão (snapshot). Edições posteriores no treinamento não alteram o item. |

### 3.7. Cópia do treinamento

Estrutura composta usada em Registro de Treino.treinamento. Guarda os dados do treinamento no momento em que o registro foi gerado, sem os exercícios.

| Atributo / Dado | Tipo conceitual | Obrigatório | Comentários |
| --- | --- | --- | --- |
| codigo | Código | Sim | Código do treinamento de origem. |
| titulo | Texto alfanumérico | Sim | Cópia do título do treinamento. |
| descricao | Texto | Não | Cópia da descrição do treinamento. |
| orientacoes | Texto (M) | Não | Cópia das orientações do treinamento. |
| duracaoEstimadaMinutos | Número inteiro | Sim | Cópia da duração estimada, em minutos. |

### 3.8. Feedback

Estrutura composta usada em Registro de Treino.feedback. É a resposta do treinador a uma sessão executada e a única forma de comunicação do MVP. Não há chat. O autor é sempre o treinador do plano, por isso não há campo de autor.

| Atributo / Dado | Tipo conceitual | Obrigatório | Comentários |
| --- | --- | --- | --- |
| data | Data e hora | Sim | Momento em que o feedback foi registrado. Não pode ser anterior à execução. |
| comentario | Texto | Sim | Avaliação geral do desempenho observado. |
| dificuldadesIdentificadas | Texto (M) | Não | Dificuldades identificadas pelo treinador. |
| orientacoes | Texto (M) | Não | Correções e ajustes para os próximos treinos ou para o plano. |

### 3.9. Exercícios Realizados

Estrutura composta multivalorada usada em Registro de Treino.exercicios. São os exercícios realizados, juntamente com sua realização e observações.

| Atributo / Dado | Tipo conceitual | Obrigatório | Comentários |
| --- | --- | --- | --- |
| exercicio | Composto (C) | Sim | Exercícios do treinamento na geração do registro |
| realizacao | Texto enumerado | PENDENTE, REALIZADO, NAO_REALIZADO | Nasce como PENDENTE. Ao registrar a sessão, o responsável marca cada exercício. |
| videos | URL | Multivalorado (M) | URL para vídeos da execução do exercício |
| observacoesEspecificas | Texto | Não | Observações sobre o exercício específico. |

## 4. Desdobramento físico ou tecnológico

Esta seção apresenta como elas serão implementadas em um banco orientado a documentos (MongoDB). Não há desdobramento relacional neste dicionário.

### 4.1. Desdobramento para banco orientado a documentos

A modelagem embute os dados que são sempre lidos juntos, referencia os que crescem ao longo do tempo ou têm ciclo de vida próprio e copia dados reduzidos para evitar junções em consultas frequentes. Todo documento é identificado pelo _id: ObjectId gerado pelo driver, exceto em responsaveis e treinadores, cujo _id é o UID do Firebase Authentication (texto); as referências a responsáveis e treinadores guardam esse UID. Datas de calendário são texto AAAA-MM-DD em cavalos e avaliacoes; em planos (dataInicio, dataFim) e registros_treino (dataPlanejada, dataExecucao) são Date do BSON, para consultas por intervalo. Referências e cópias resumidas guardam o _id do documento de origem. Os nomes de campos seguem os da seção 2, sem acentos e com listas no plural.

#### Coleções sugeridas

| Entidade conceitual | Coleção | Estratégia |
| --- | --- | --- |
| Responsável | responsaveis | Documento próprio, com os dados de acesso, a lista resumida dos seus cavalos com o tipo de responsabilidade sobre cada um (cavalos) e as modalidades (modalidades). |
| Treinador | treinadores | Documento próprio, com dados de acesso, perfil profissional (experiências e certificações como referências a arquivos PDF) e regiões de atendimento (listas embutidas), mais as listas resumidas de cavalos (cavalos) e de clientes (clientes). |
| (técnica, sem entidade conceitual) | emails | Reserva de e-mails, para garantir unicidade entre responsáveis e treinadores e rotear o login. Ver o exemplo abaixo. |
| Cavalo | cavalos | Documento próprio. Histórico de lesões embutido. Proprietário, atleta, modalidade e treinadores como referência resumida. Lista resumida de avaliações (avaliacoes) e resumo do plano atual (planoAtual). |
| Avaliação | avaliacoes | Documento próprio, com cavalo, treinador e modalidades como referência resumida. |
| Exercício | exercicios | Catálogo próprio. Materiais embutidos. Guarda o treinador cadastrante e, nos exercícios ESPECIFICO, a referência resumida do cavalo. |
| Treinamento | treinamentos | Catálogo que contempla detalhes dos exercícios juntamento com o _id de cada um |
| Plano de Treinamento | planos | Documento próprio. Planejamento embutido, com snapshot dos treinamentos e dos exercícios em uso. Cópia da avaliação inicial embutida (avaliacaoInicial). |
| Registro de Treino, Feedback | registros_treino | Um documento por item do planejamento. Snapshot do treinamento, exercícios em uso e feedback embutidos. |
| Modalidade | modalidades | Catálogo próprio, pequeno e raramente alterado. Referenciado de forma resumida (_id, codigo e nome) por responsaveis, cavalos e avaliacoes. |
| Dashboard de evolução | (nenhuma) | Calculado por agregação sobre registros_treino. |

#### Exemplo de documento da coleção responsaveis

```
{
  "_id": "66e1a0c2f1b2c3d4e5f60015",
  “codigo”: 42,
  "nome": "Maria Oliveira",
  "email": "maria.oliveira@example.com",
  "situacaoCadastral": “ATIVO”,
  "cavalos": [
    {
      "_id": "66e1a0c2f1b2c3d4e5f60050",
      “codigo”: “123123456789012”,
      "nome": "Trovão",
      "responsabilidades": ["PROPRIETARIO", "ATLETA"]
    },
    {
      "_id": "66e1a0c2f1b2c3d4e5f60051",
      “codigo”: “124123456789012”,
      "nome": "Estrela do Sul",
      "responsabilidades": ["PROPRIETARIO"]
    }
  ],
  "modalidades": [
    { "_id": "66e1a0c2f1b2c3d4e5f6a001", “codigo”: 12, "nome": "Salto" }
  ],
  "criadoEm": "2026-08-20T09:00:00-03:00",
  "atualizadoEm": "2026-08-25T09:30:00-03:00"
}
```

A lista cavalos guarda, para cada cavalo ativo do responsável, o _id, o nome e as responsabilidades dele sobre o cavalo (PROPRIETARIO, ATLETA ou ambas). Serve à tela inicial do responsável, sem consultar cavalos. Os treinadores não são copiados para esta lista: como um cavalo pode ter vários, mantê-los aqui multiplicaria as atualizações. modalidades guarda o _id, o codigo e o nome de cada modalidade do responsável.

#### Exemplo de documento da coleção treinadores

```
{
  "_id": "66e1a0c2f1b2c3d4e5f60007",
  "nome": "Carlos Mendes",
  “codigo”: 92,
  "email": "carlos.mendes@example.com",
  "situacaoProfissional": “DISPONIVEL”,
  "modalidades": ["Adestramento", "Salto"],
  "experiencias": "/arquivos/treinadores/66e1a0c2f1b2c3d4e5f60007/experiencia_1.pdf",
  "certificacoes": ["/arquivos/treinadores/66e1a0c2f1b2c3d4e5f60007/certificacao_1.pdf"],
  "regioesAtendimento": [
    { "estado": "SP", "cidade": "Campinas", "complemento": "Região de Barão Geraldo" },
    { "estado": "SP", "cidade": "Valinhos" }
  ],
  "cavalos": [
    {
      "_id": "66e1a0c2f1b2c3d4e5f60050",
      “codigo”: “123123456789012”,
      "nome": "Trovão"
    }
  ],
  "clientes": [
    { "_id": "66e1a0c2f1b2c3d4e5f60015",   “codigo”: 42, "nome": "Maria Oliveira" }
  ],
  "criadoEm": "2026-08-20T10:00:00-03:00",
  "atualizadoEm": "2026-09-01T14:00:00-03:00"
}
```

regioesAtendimento é uma lista embutida de estruturas compostas, e o complemento é omitido quando não há. experiencias guarda o caminho de um único PDF (ou null) e certificacoes, a lista de caminhos dos PDFs, que ficam fora do banco. cavalos guarda os cavalos ativos que o treinador acompanha, e clientes guarda os responsáveis (proprietários ou atletas) de ao menos um desses cavalos. Ambos são derivados de cavalos (ver 5.2).

#### Exemplo de documento da coleção emails

```
{
  "_id": "carlos.mendes@example.com",
  “codigo”: 42,
  "tipoConta": "TREINADOR",
  "usuarioId": "66e1a0c2f1b2c3d4e5f60007",
  "criadoEm": "2026-08-20T10:00:00-03:00"
}
```

O e-mail, já em minúsculas, é o próprio _id. Como o MongoDB não permite dois documentos com o mesmo _id na coleção, a unicidade fica garantida pelo banco. O campo tipoConta (RESPONSAVEL ou TREINADOR) é técnico: indica em qual coleção está o usuário cujo _id está em usuarioId.

#### Exemplo de documento da coleção cavalos

```
{
  "_id": "66e1a0c2f1b2c3d4e5f60050",
  “codigo”: “123123456789012”,
  "nome": "Trovão",
  "dataNascimento": "2016-04-10",
  "raca": "Brasileiro de Hipismo",
  "pelagem": "Tordilho",
  "sexo": "MACHO",
  "imagens": ["/fotos/cavalos/66e1a0c2f1b2c3d4e5f60050.jpg"],
  "modalidade": { "_id": "66e1a0c2f1b2c3d4e5f6a001",   “codigo”: 12, "nome": "Salto" },
  "limitacoesFisicas": ["Sensibilidade no casco posterior esquerdo em terreno duro"],
  "observacoesSaude": ["Vacinas em dia"],
  "historicoLesoes": [
    { "data": "2025-03-12", "descricao": "Distensão leve, repouso de 3 semanas" }
  ],
  "situacaoCadastral": “ATIVO”,
  "proprietario": { "_id": "66e1a0c2f1b2c3d4e5f60015",   “codigo”: 42, "nome": "Maria Oliveira" },
  "atleta": { "_id": "66e1a0c2f1b2c3d4e5f60015",   “codigo”: 42, "nome": "Maria Oliveira" },
  "treinadores": [
    { "_id": "66e1a0c2f1b2c3d4e5f60007",   “codigo”: 92, "nome": "Carlos Mendes" }
  ],
  "planoAtual": { "_id": "66e1a0c2f1b2c3d4e5f6e005", “codigo”: 682, "titulo": "Condicionamento para percursos de 1,00 m", "dataInicio": "2026-09-07", "dataFim": "2026-10-04" },
  "avaliacoes": [
    { "_id": "66e1a0c2f1b2c3d4e5f6b003",   “codigo”: 982,"data": "2026-09-05", "treinador": { "_id": "66e1a0c2f1b2c3d4e5f60007",   “codigo”: 92,"nome": "Carlos Mendes" } },
    { "_id": "66e1a0c2f1b2c3d4e5f6b002",   “codigo”: 990,"data": "2026-08-27", "treinador": { "_id": "66e1a0c2f1b2c3d4e5f60007",   “codigo”: 92,"nome": "Carlos Mendes" } }
  ],
  "criadoEm": "2026-08-25T09:30:00-03:00",
  "atualizadoEm": "2026-09-06T16:20:00-03:00"
}
```

treinadores é uma lista resumida e fica vazia quando o cavalo não tem treinador e tem no máximo um item. atleta e os itens de treinadores guardam também vinculadoEm (data do vínculo), usada na ordenação da lista de cavalos. proprietario é obrigatório e atleta é omitido quando o cavalo não tem atleta; os dois podem apontar para o mesmo responsável, como neste exemplo. planoAtual existe apenas enquanto houver um plano ATIVO e é omitido caso contrário. avaliacoes é o histórico resumido, em ordem decrescente de data (a primeira é a mais recente), e o conteúdo completo fica na coleção avaliacoes.

#### Exemplo de documento da coleção avaliacoes

```
{
  "_id": "66e1a0c2f1b2c3d4e5f6b003",
  “codigo”: 42,
  "cavalo": { "_id": "66e1a0c2f1b2c3d4e5f60050",   “codigo”: “123123456789012”, "nome": "Trovão" },
  "treinador": { "_id": "66e1a0c2f1b2c3d4e5f60007",   “codigo”: 92, "nome": "Carlos Mendes" },
  "data": "2026-09-05",
  "condicionamentoFisicoObservado": "Fôlego regular após 20 minutos de trabalho; boa musculatura de dorso",
  "limitacoes": "Evitar terreno duro",
  "dificuldades": "Perde ritmo após a segunda linha de obstáculos",
  "modalidades": [{ "_id": "66e1a0c2f1b2c3d4e5f6a001",   “codigo”: 12, "nome": "Salto" }],
  "observacoes": ["Boa disposição, reage bem a comandos de perna"],
  "criadoEm": "2026-09-05T18:00:00-03:00",
  "atualizadoEm": "2026-09-05T18:00:00-03:00"
}
```

#### Exemplo de documento da coleção modalidades

```
{
  "_id": "66e1a0c2f1b2c3d4e5f6a001",
  “codigo”: 12,
  "nome": "Salto",
  "descricao": "Modalidade em que o conjunto percorre uma pista com obstáculos a serem saltados."
}
```

#### Exemplo de documento da coleção exercicios

```
{
  "_id": "66e1a0c2f1b2c3d4e5f6c010",
  “codigo”: 23,
  "nome": "Transições trote-galope",
  "descricao": "Alternar trote e galope em intervalos definidos para trabalhar equilíbrio e condicionamento.",
  "orientacoes": ["Manter contato leve com as rédeas", "Repetir em ambas as mãos"],
  "duracaoPadraoMinutos": 20,
  "materiais": [
    { "descricao": "Cavalete", "quantidade": 2 },
    { "descricao": "Vara", "quantidade": 3 }
  ],
  "privacidade": "ESPECIFICO",
  "cavalo": { "_id": "66e1a0c2f1b2c3d4e5f60050",   “codigo”: “123123456789012”, "nome":         "Trovão" },
  “ativo”: true,
  "imagens": [ "fotos/exercicios/50_1.jpg", "fotos/exercicios/50_2.jpg" ],
  "videos": [ “videos/exercicios/50_1.mp4" ],,
  "cadastrante": "TREINADOR",
  "treinador": { "_id": "66e1a0c2f1b2c3d4e5f60007",   “codigo”: 92,"nome": "Carlos Mendes" },
  "criadoEm": "2026-09-06T11:00:00-03:00",
  "atualizadoEm": "2026-09-06T11:00:00-03:00"
}
```

Em um exercício cadastrado pela plataforma, cadastrante é PLATAFORMA, privacidade é GENERICO e o campo treinador é omitido. O campo cavalo existe apenas quando privacidade é ESPECIFICO. Quando o cadastrante é um treinador, a referência a ele fica sempre no documento do exercício. materiais é uma lista embutida de estruturas compostas, com descrição e quantidade.

#### Exemplo de documento da coleção treinamentos

```
{
  "_id": "66e1a0c2f1b2c3d4e5f6d001",
  “codigo”: 42,
  "titulo": "Trabalho de transições",
  "descricao": "Sessão focada em equilíbrio nas transições de andamento.",
  "orientacoes": ["Encerrar com 5 minutos de passo"],
  "duracaoEstimadaMinutos": 45,
  "treinador": { "_id": "66e1a0c2f1b2c3d4e5f60007",   “codigo”: 92,"nome": "Carlos Mendes" },
  "exercicios": [
    {
      "_id": "66e1a0c2f1b2c3d4e5f6c011",
      “codigo”: 12,
      "nome": "Aquecimento ao passo",
      "descricao": "Caminhada em pista para aquecimento muscular.",
      "orientacoes": ["Deixar o pescoço solto"],
      "duracaoPadraoMinutos": 10
    },
    {
      "_id": "66e1a0c2f1b2c3d4e5f6c010",
      “codigo”: 23,
      "nome": "Transições trote-galope",
      "descricao": "Alternar trote e galope em intervalos definidos para trabalhar equilíbrio e condicionamento.",
      "orientacoes": ["Manter contato leve com as rédeas", "Repetir em ambas as mãos"],
      "duracaoPadraoMinutos": 20
    }
  ],
  "criadoEm": "2026-09-06T11:30:00-03:00",
  "atualizadoEm": "2026-09-06T11:30:00-03:00"
}
```

Os campos nome, descricao e orientacoes de cada exercício em uso são o snapshot copiado no momento em que o exercício foi incluído no treinamento, e o _id é o do exercício de origem. duracaoPadraoMinutos começa com os valores padrão do exercício e pode ser ajustada pelo treinador. O treinamento é exclusivo do treinador que o criou.

#### Exemplo de documento da coleção planos

```
{
  "_id": "66e1a0c2f1b2c3d4e5f6e005",
  “codigo”: 682,
  "titulo": "Condicionamento para percursos de 1,00 m",
  "objetivo": "Ganhar condicionamento para percursos de 1,00 m",
  "cavalo": { "_id": "66e1a0c2f1b2c3d4e5f60050",   “codigo”: “123123456789012”,"nome": "Trovão" },
  "treinador": { "_id": "66e1a0c2f1b2c3d4e5f60007",  “codigo”: 92, "nome": "Carlos Mendes" },
  "avaliacaoInicial": {
    "_id": "66e1a0c2f1b2c3d4e5f6b003",
    “codigo”: 42,
    "data": "2026-09-05",
    "condicionamentoFisicoObservado": "Fôlego regular após 20 minutos de trabalho; boa musculatura de dorso",
    "limitacoes": "Evitar terreno duro",
    "dificuldades": "Perde ritmo após a segunda linha de obstáculos",
    "modalidades": [{ "_id": "66e1a0c2f1b2c3d4e5f6a001",   “codigo”: 12, "nome": "Salto" }],
    "observacoes": ["Boa disposição, reage bem a comandos de perna"]
  },
  "status": "ATIVO",
  "dataInicio": "2026-09-07",
  "dataFim": "2026-10-04",
  "planejamento": [
    {
      "codigo": 1,
      "ativo": true, "diasSemana": ["TERCA", "SABADO"],
      "treinamento": {
        "_id": "66e1a0c2f1b2c3d4e5f6d001",
        “codigo”: 42,
        "titulo": "Trabalho de transições",
        "descricao": "Sessão focada em equilíbrio nas transições de andamento.",
        "orientacoes": ["Encerrar com 5 minutos de passo"],
        "duracaoEstimadaMinutos": 45,
        "exercicios": [
          {
            "_id": "66e1a0c2f1b2c3d4e5f6c011",
            “codigo”: 923,
            "nome": "Aquecimento ao passo",
            "descricao": "Caminhada em pista para aquecimento muscular.",
            "orientacoes": ["Deixar o pescoço solto"],
            "duracaoPadraoMinutos": 10
          },
          {
            "_id": "66e1a0c2f1b2c3d4e5f6c010",
            “codigo”: 23,
            "nome": "Transições trote-galope",
            "descricao": "Alternar trote e galope em intervalos definidos para trabalhar equilíbrio e condicionamento.",
            "orientacoes": ["Manter contato leve com as rédeas", "Repetir em ambas as mãos"],
            "duracaoPadraoMinutos": 20
          }
        ]
      }
    },
    {
      "codigo": 2,
      "ativo": true, "diasSemana": ["QUINTA"],
      "treinamento": {
        "_id": "66e1a0c2f1b2c3d4e5f6d002",
        “codigo”: 976,
        "titulo": "Trabalho de solo e alongamento",
        "descricao": "Sessão leve de recuperação com alongamentos.",
        "orientacoes": [],
        "duracaoEstimadaMinutos": 30,
        "exercicios": [
          {
            "_id": "66e1a0c2f1b2c3d4e5f6c012",
            “codigo”: 6767
            "nome": "Alongamento ativo",
            "descricao": "Sequência de alongamentos conduzidos no solo.",
            "orientacoes": [],
            "duracaoPadraoMinutos": 15
          }
        ]
      }
    }
  ],
  "criadoEm": "2026-09-06T16:00:00-03:00",
  "atualizadoEm": "2026-09-06T16:20:00-03:00"
}
```

Os demais itens do planejamento seguem a mesma estrutura e foram omitidos por brevidade. Um treinamento aparece em um único item ativo, que reúne todos os seus dias da semana. O item não guarda datas: cada data entre dataInicio e dataFim que cai em diasSemana gera um registro, e a semana é calculada a partir dessa data e de dataInicio. ativo indica se o item continua em uso depois de uma edição do plano. avaliacaoInicial é uma cópia da avaliação que originou o plano, com o _id da original.

#### Exemplos de documentos da coleção registros_treino

Registro já executado, com feedback:

```
{
  "_id": "66e1a0c2f1b2c3d4e5f6f101",
   “codigo”: 7676,
  "plano": { "_id": "66e1a0c2f1b2c3d4e5f6e005",   “codigo”: 682, "titulo": "Condicionamento para percursos de 1,00 m" },
  "itemPlanejamento": 1,
  "responsavel": { "_id": "66e1a0c2f1b2c3d4e5f60015",  “codigo”: 42, "nome": "Maria Oliveira" },
  "cavalo": { "_id": "66e1a0c2f1b2c3d4e5f60050",   “codigo”: “123123456789012”, "nome": "Trovão" },
  "treinador": { "_id": "66e1a0c2f1b2c3d4e5f60007",   “codigo”: 92, "nome": "Carlos Mendes" },
  "semana": 1,
  "status": "REALIZADO",
  "dataPlanejada": "2026-09-08",
  "dataExecucao": "2026-09-08",
  "duracaoEfetivaMinutos": 40,
  "percepcaoDesempenho": 8,
  "dificuldade": "Perdeu ritmo na transição para o galope à esquerda",
  "observacoes": ["Cavalo mais agitado no início"],
  "treinamento": {
    "_id": "66e1a0c2f1b2c3d4e5f6d001",
    “codigo”: 42,
    "titulo": "Trabalho de transições",
    "descricao": "Sessão focada em equilíbrio nas transições de andamento.",
    "orientacoes": ["Encerrar com 5 minutos de passo"],
    "duracaoEstimadaMinutos": 45
  },
  "exercicios": [
    {
      "exercicio": {
        "_id": "66e1a0c2f1b2c3d4e5f6c011",
        “codigo”: 492,
        "nome": "Aquecimento ao passo",
        "descricao": "Caminhada em pista para aquecimento muscular.",
        "orientacoes": ["Deixar o pescoço solto"],
        “video”: [“videos/execucao/50_1.mp4"],
        "duracaoPadraoMinutos": 10
      },
      "realizacao": "REALIZADO"
    },
    {
      "exercicio": {
        "_id": "66e1a0c2f1b2c3d4e5f6c010",
        “codigo”: 23,
        "nome": "Transições trote-galope",
        "descricao": "Alternar trote e galope em intervalos definidos para trabalhar equilíbrio e condicionamento.",
        "orientacoes": ["Manter contato leve com as rédeas", "Repetir em ambas as mãos"],
        "duracaoPadraoMinutos": 20
      },
      "realizacao": "REALIZADO",
      "observacoesEspecificas": "Recusou o galope à esquerda na primeira tentativa"
    }
  ],
  "feedback": {
    "data": "2026-09-08T20:10:00-03:00",
    "comentario": "Boa evolução no equilíbrio nas transições.",
    "dificuldadesIdentificadas": ["Perde ritmo na transição para o galope à esquerda"],
    "orientacoes": ["Reduzir o tempo de galope no próximo treino", "Repetir a transição à esquerda com mais calma"]
  },
  "criadoEm": "2026-09-06T16:20:00-03:00",
  "atualizadoEm": "2026-09-08T20:10:00-03:00"
}
```

Registro ainda planejado, criado na ativação do plano:

```
{
  "_id": "66e1a0c2f1b2c3d4e5f6f102",
  “codigo”: 699,
  "plano": { "_id": "66e1a0c2f1b2c3d4e5f6e005",   “codigo”: 682, "titulo": "Condicionamento para percursos de 1,00 m" },
  "itemPlanejamento": 2,
  "responsavel": { "_id": "66e1a0c2f1b2c3d4e5f60015",   “codigo”: 42,"nome": "Maria Oliveira" },
  "cavalo": { "_id": "66e1a0c2f1b2c3d4e5f60050",   “codigo”: “123123456789012”, "nome": "Trovão" },
  "treinador": { "_id": "66e1a0c2f1b2c3d4e5f60007",   “codigo”: 92, "nome": "Carlos Mendes" },
  "semana": 1,
  "status": "PLANEJADO",
  "dataPlanejada": "2026-09-10",
  "treinamento": {
    "_id": "66e1a0c2f1b2c3d4e5f6d002",
    “codigo”: 567,
    "titulo": "Trabalho de solo e alongamento",
    "descricao": "Sessão leve de recuperação com alongamentos.",
    "orientacoes": [],
    "duracaoEstimadaMinutos": 30
  },
  "exercicios": [
    {
      "exercicio": {
        "_id": "66e1a0c2f1b2c3d4e5f6c012",
        “codigo”: 678,
        "nome": "Alongamento ativo",
        "descricao": "Sequência de alongamentos conduzidos no solo.",
        "orientacoes": [],
        "duracaoPadraoMinutos": 15
      },
      "realizacao": "PENDENTE"
    }
  ],
  "criadoEm": "2026-09-06T16:20:00-03:00",
  "atualizadoEm": "2026-09-06T16:20:00-03:00"
}
```

Neste documento, responsavel recebe o atleta do cavalo, que é quem executa o treino, e cavalo e treinador são copiados do plano na geração do registro. A cópia existe para atender às consultas de agenda e de fila de feedback sem precisar de junção. treinamento e exercicios[].exercicio são cópias do item itemPlanejamento do plano, sem consulta ao catálogo. Em cada item de exercicios, exercicio guarda a cópia do exercício em uso, e realizacao e observacoesEspecificas guardam o que o responsável registra sobre ele (observacoesEspecificas é omitido quando vazio). percepcaoDesempenho é um inteiro de 1 a 10, e dificuldade é texto livre.

### 4.2. Justificativa do desdobramento

responsaveis e treinadores separados: refletem as entidades da seção 2. A unicidade do e-mail entre as duas coleções é resolvida pela coleção emails (ver 4.1).

Listas e resumos em responsaveis, treinadores e cavalos: evitam junções nas telas iniciais e na tela do cavalo. São pequenos e derivados de relacionamentos, então a fonte da verdade continua nas coleções de origem. O custo é escrever em mais de um documento, o que exige transação (ver 5.2).

cavalos, avaliacoes, exercicios, treinamentos e modalidades em coleções próprias: têm ciclo de vida independente e são lidos por perfis diferentes. O histórico de lesões fica embutido no cavalo, os materiais no exercício e os exercícios em uso no treinamento. modalidades é um catálogo pequeno referenciado por vários documentos, e a cópia resumida (_id, codigo e nome) evita consultá-lo nas telas.

planos com planejamento e avaliação inicial embutidos: o plano é lido e editado como um todo, e seu tamanho fica muito abaixo do limite de 16 MB por documento. As cópias (snapshots) dispensam consultar avaliacoes, treinamentos e exercicios ao abrir o plano (ver os exemplos em 4.1).

registros_treino em coleção própria: cresce a cada sessão, é atualizado por duas pessoas e sustenta o dashboard. O feedback é embutido por ser 1:1. Os campos responsavel, cavalo e treinador são copiados de propósito, para a agenda e a fila de feedback não consultarem o plano.

Nomes copiados: podem ficar defasados se o original mudar, o que é aceitável para exibição. O _id é a fonte da verdade.

Dashboard sem coleção: é calculado por agregação sobre os registros, o que evita totais que poderiam ficar inconsistentes.

_id como ObjectId: é gerado pelo driver na aplicação, é único sem coordenação entre servidores e já tem índice único por padrão. Em responsaveis e treinadores, o _id é o UID do Firebase Authentication. O campo codigo é mantido como identificador legível: um inteiro sequencial gerado pela coleção técnica contadores (um documento { _id: nome da coleção, seq } por coleção, incrementado na mesma transação da inserção) e protegido pelo índice único codigo_unico. No cavalo, codigo é o número do microchip.

## 5. Consultas, índices e observações de arquitetura

### 5.1. Consultas esperadas

Além dos índices abaixo, toda coleção possui o índice único padrão do MongoDB em _id, usado nas leituras de um documento pelo seu identificador.

| Consulta esperada | Campos envolvidos | Índices sugeridos | Observações |
| --- | --- | --- | --- |
| Autenticar por e-mail | emails._id, emails.usuarioId; responsaveis._id ou treinadores._id | Índice padrão de _id em emails, responsaveis e treinadores | Consulta direta por chave. E-mail normalizado em minúsculas. |
| Listar cavalos de um responsável | responsaveis.cavalos | Índice padrão de _id | Uma leitura do documento do responsável. |
| Listar cavalos de um treinador | treinadores.cavalos | Índice padrão de _id | Uma leitura do documento do treinador. |
| Listar clientes de um treinador | treinadores.clientes | Índice padrão de _id | Uma leitura do documento do treinador. |
| Abrir a tela do cavalo (plano atual e histórico de avaliações) | cavalos.planoAtual, cavalos.avaliacoes | Índice padrão de _id | Uma leitura do documento do cavalo. O conteúdo completo de plano e avaliação é buscado sob demanda. |
| Abrir um plano com avaliação inicial e planejamento | planos.avaliacaoInicial, planos.planejamento | Índice padrão de _id | Uma leitura, sem consultar avaliacoes, treinamentos nem exercicios. |
| Buscar o plano ativo de um cavalo | planos.cavalo._id, planos.status | idx_planos_cavalo_ativo (único parcial: cavalo._id, filtro status = ATIVO) | Garante no banco a regra de um plano ativo por cavalo. |
| Listar histórico de planos de um cavalo | planos.cavalo._id, planos.dataInicio | idx_planos_cavalo_data | Ordenação decrescente por dataInicio. |
| Listar planos de um treinador por status | planos.treinador._id, planos.status | idx_planos_treinador_status | Visão geral dos planos que o treinador gerencia. |
| Listar treinamentos de um treinador | treinamentos.treinador._id | idx_treinamentos_treinador | Catálogo do treinador. Não é visível a outros treinadores. |
| Buscar treinamento por título | treinamentos.titulo | idx_treinamentos_titulo (texto, idioma portuguese) | Busca ao montar o planejamento. Filtrar também por treinador. |
| Listar exercícios disponíveis para um treinador | exercicios.treinador._id | idx_exercicios_treinador | Retorna os exercícios cadastrados pelo treinador (consulta com $or). Cada ramo do $or usa o seu próprio índice. |
| Buscar exercício por nome | exercicios.nome | idx_exercicios_nome (texto, idioma portuguese) | Busca ao montar treinamentos. |
| Listar treinos de um responsável por período e status | registros_treino.responsavel._id, dataPlanejada, status | idx_registros_responsavel_data | Agenda do responsável. Treinos atrasados são os PLANEJADO com dataPlanejada excedente a data da consulta. O responsável gravado é o atleta; o proprietário consulta pelos seus cavalos. |
| Listar treinos de um cavalo por período e status | registros_treino.cavalo._id, dataPlanejada, status | idx_registros_cavalo_data | Também alimenta o dashboard. |
| Listar registros de um plano | registros_treino.plano._id, itemPlanejamento, dataPlanejada | idx_registros_plano_item (único) | O índice único garante um registro por item do planejamento e data. A lista de um plano é pequena e pode ser ordenada por semana e dataPlanejada em memória. |
| Listar registros executados sem feedback | registros_treino.treinador._id, status, dataExecucao | idx_registros_treinador_status | Fila de trabalho do treinador. Filtrar status em REALIZADO ou PARCIAL e sem o campo feedback. |
| Consultar o conteúdo completo das avaliações de um cavalo | avaliacoes.cavalo._id, data | idx_avaliacoes_cavalo_data | Ordenação decrescente por data. O resumo já está em cavalos.avaliacoes. |
| Calcular o dashboard de um cavalo | registros_treino.cavalo._id, status, dataPlanejada, semana | idx_registros_cavalo_data | Agregação ($match seguido de $group), excluindo CANCELADO. Sem coleção adicional. |
| Reconstruir as listas resumidas (reconciliação) | cavalos.proprietario._id, cavalos.atleta._id, cavalos.treinadores._id | idx_cavalos_proprietario, idx_cavalos_atleta, idx_cavalos_treinadores (multikey) | Usada por rotina de correção e nas checagens de acesso. Em caso de divergência, vale a coleção de origem. |
| Listar modalidades | modalidades.nome | idx_modalidades_nome (único) | Catálogo pequeno, lido inteiro para preencher seleções. O índice único evita modalidades duplicadas. |

### 5.2. Regras e observações

#### Acesso e vínculo

- O e-mail é único entre responsáveis e treinadores, garantido pela coleção emails (ver 4.1). A senha fica apenas no Firebase Authentication, nunca no banco.
- Um usuário que atue como um treinador e responsável (proprietário e/ou atleta) por um cavalo ao mesmo tempo deve possuir cadastros isolados para cada função.
- Um cavalo tem um proprietário obrigatório e um atleta opcional, que podem ser o mesmo responsável, e no máximo um treinador por vez.
- Apenas treinadores vinculados ao cavalo podem criar avaliações e planos para ele. O feedback é dado pelo treinador do plano.
- Um treinador só pode ser desvinculado do cavalo se não for o autor do plano ATIVO dele.
- Responsáveis só acessam cavalos, planos e registros dos cavalos em que são proprietários ou atletas. Treinadores só acessam os dos cavalos que acompanham, além dos seus próprios treinamentos.
- As regiões de atendimento são informativas: não há busca de profissionais no MVP e, por isso, nenhum índice sobre regioesAtendimento.
- Em alguns casos o atleta responsável não é um cliente direto do treinador, mas sim um prestador de serviços para um proprietário. O campo treinadores.clientes mantém os vínculos com os atletas em todos os casos.

#### Exercícios e treinamentos

- O campo treinador do exercício é obrigatório quando cadastrante for TREINADOR, e o campo cavalo, quando privacidade for ESPECIFICO.
- Todo treinamento tem um treinador autor e é visível apenas a ele. Um treinamento só pode incluir exercícios que o treinador enxerga.
- Editar um exercício ou um treinamento nunca altera cópias já gravadas (ver 4.2). Exercícios e treinamentos que já foram usados não devem ser removidos fisicamente: usar exclusão lógica.

#### Plano e registros

- Um plano já é criado ATIVO, opcionalmente a partir de uma avaliação do mesmo cavalo, que é copiada para avaliacaoInicial. A partir daí, a avaliação não pode mais ser editada. Correções são feitas criando uma nova avaliação.
- Um plano só pode ser criado com ao menos um item no planejamento e se o cavalo não tiver outro plano ATIVO.
- O item não guarda datas. Os registros recebem as datas entre dataInicio e dataFim que caem nos diasSemana do item; a semana é calculada a partir de dataPlanejada e dataInicio e gravada no registro na geração.
- A criação do plano é uma única transação: grava o plano ATIVO, gera os registros PLANEJADO (um por data de cada item) e grava o planoAtual no cavalo. Se o cavalo tiver um plano ATIVO já vencido, ele é concluído na mesma transação.
- Um cavalo tem no máximo um plano ATIVO, garantido pelo índice único parcial idx_planos_cavalo_ativo. Um item do planejamento gera no máximo um registro por data, garantido pelo índice idx_registros_plano_item.
- Ao cancelar um plano, os registros PLANEJADO de hoje em diante passam para CANCELADO e saem do cálculo de cumprimento; os de dias anteriores passam para NAO_REALIZADO, e o planoAtual é removido do cavalo na mesma transação. Não há rotina de conclusão: um plano ATIVO cuja dataFim já passou é exibido como CONCLUIDO, e só é gravado assim (com os PLANEJADO restantes passando para NAO_REALIZADO) quando um novo plano é criado para o cavalo.
- A execução só pode ser registrada pelo atleta do cavalo e no dia planejado. O status é derivado das marcações dos exercícios: todos REALIZADO resultam em REALIZADO, ao menos um em PARCIAL e nenhum em NAO_REALIZADO. dataExecucao é sempre gravada. Em REALIZADO e PARCIAL, duracaoEfetivaMinutos (1 a 480) e percepcaoDesempenho (1 a 10) são obrigatórios; em NAO_REALIZADO, ficam ausentes, assim como dificuldade.
- O feedback só pode ser criado pelo treinador do plano, em registros cuja execução foi registrada pelo atleta (REALIZADO, PARCIAL ou NAO_REALIZADO com dataExecucao), e existe um por registro. O NAO_REALIZADO gerado pelo cancelamento ou encerramento do plano não recebe feedback.
- No cálculo do percentual de cumprimento de treinamentos, o percentual de cumprimento de cada treinamento é calculado em razão entre duração efetiva e duração estimada.
- A realização de cada exercício não entra diretamente em nenhuma métrica, mas define o status do registro (ver acima), que é a base do dashboard.

#### Manutenção das listas resumidas e cópias

A fonte da verdade está sempre na coleção de origem. Cada operação abaixo é uma única transação.

- Cadastrar um cavalo: cria o documento em cavalos e adiciona o resumo em responsaveis.cavalos do proprietário e do atleta (um único item com as duas responsabilidades quando forem a mesma pessoa).
- Vincular ou desvincular um treinador: adiciona ou remove o treinador em cavalos.treinadores e o cavalo em treinadores.cavalos. Ao vincular, o proprietário e o atleta são adicionados a treinadores.clientes. Ao desvincular, cada um só é removido se não restar nenhum cavalo dele com esse treinador.
- Alterar o proprietário ou o atleta: atualiza cavalos, ajusta os itens de responsaveis.cavalos do responsável antigo e do novo e ajusta treinadores.clientes de todos os treinadores do cavalo pela mesma regra.
- Desativar um cavalo: remove o resumo de responsaveis.cavalos e de treinadores.cavalos, e ajusta treinadores.clientes pela mesma regra.
- Criar uma avaliação: cria o documento em avaliacoes e insere o resumo em cavalos.avaliacoes, mantendo a ordem decrescente de data. A edição de uma avaliação ainda não vinculada a plano atualiza o resumo.
- Alterar o título de um plano ativo: atualiza também cavalos.planoAtual e o plano.titulo dos seus registros.
- Alterar nome (responsável, treinador, cavalo ou modalidade): propaga a mudança às cópias vivas (listas resumidas e referências em documentos correntes). Essa propagação pode ser assíncrona, pois o _id continua correto enquanto isso. Documentos históricos podem manter o nome da época.
- Divergências: em caso de conflito entre a lista resumida e a coleção de origem, vale a origem. Uma rotina de reconciliação pode reconstruir as listas (ver 5.1).

#### Histórico e integridade

- Registros de treino, avaliações e feedbacks não devem ser removidos fisicamente em uso normal. Usar status ou ativo para exclusão lógica.
- As imagens do cavalo e os PDFs de experiências e certificações do treinador ficam fora do banco, em um serviço de armazenamento de arquivos. O documento guarda apenas o caminho ou a URL.
- As informações de saúde e as avaliações têm caráter esportivo e informativo, sem função de diagnóstico veterinário.
