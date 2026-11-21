// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 04/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos do desvínculo de atleta ou treinador; NAO_REALIZADO
// deixa de ser CONCLUIDO no treino do dia; nome da pessoa do card pode
// ser null.
//
// Data: 01/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: HorseView e HorseCurrentPlanResult substituídos por
// HorseProfile (perfil completo, com permissões e situação do treino do
// dia); inclusão de saúde restrita ao proprietário.
// Alteração: Microchip editável, modalidade obrigatória e relação
// TREINADOR na consulta.
// Alteração: Listas de saúde editadas por inclusão e remoção; datas do
// plano atual; data do vínculo de atleta e treinador; tipos dos vínculos
// e da lista de cavalos.
// Alteração: Tipos da inclusão de saúde/lesão e do plano atual.
// Alteração: Fonte única dos itens das listas resumidas (responsaveis e
// treinadores), também usados por authentication; sem o alias GuardianRef.
// Alteração: HorseListSource (projeção da lista), antes no repository.
//
// Data: 27/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos do envio, da confirmação e da remoção de imagens.
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipos do documento, do cadastro, da edição e da consulta.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Tipo da referência resumida de treinador.
// -----------------------------------------------------------------------------

import type {ObjectId} from "mongodb";

// Referência resumida a um treinador dentro de cavalos.treinadores.
export type HorseTrainerRef = {_id: string; nome: string};

export type HorseSex = "MACHO" | "FEMEA";

export type HorseResponsibility = "PROPRIETARIO" | "ATLETA";

// Relação de quem consulta com o cavalo (responsabilidade ou treinador).
export type HorseRelation = HorseResponsibility | "TREINADOR";

// Registro de lesão (historicoLesoes). Datas em AAAA-MM-DD.
export type InjuryRecord = {
    data: string;
    descricao: string;
    prescricao?: string;
};

// Referência resumida a uma conta (responsável ou treinador): proprietario e
// atleta do cavalo, treinadores.clientes.
export type AccountRef = {_id: string; codigo: number; nome: string};

// Atleta e treinador guardam a data do vínculo, usada na ordenação da
// lista ("adicionados recentemente"). Ausente em vínculos anteriores a
// 03/11/2026, que usam a data de cadastro do cavalo.
export type LinkedRef = AccountRef & {vinculadoEm?: Date};

// Resumo do plano ATIVO (planoAtual).
export type CurrentPlanRef = {
    _id: ObjectId;
    codigo: number;
    titulo: string;
    // Datas do plano (AAAA-MM-DD), para a aba "Plano atual".
    dataInicio: string;
    dataFim: string;
};

// Coleção 'cavalos'. 'codigo' é o microchip (15 dígitos, único).
export type HorseDocument = {
    _id: ObjectId;
    codigo: string;
    nome: string;
    // A idade não é armazenada: é calculada a partir desta data.
    dataNascimento: string;
    raca: string;
    pelagem: string;
    sexo: HorseSex;
    // Caminhos no Storage (formato do DD), na ordem de envio.
    imagens: string[];
    // Obrigatória desde 03/11/2026; cavalos cadastrados antes podem não ter.
    modalidade?: {_id: ObjectId; codigo: number; nome: string};
    limitacoesFisicas: string[];
    observacoesSaude: string[];
    // Ordem decrescente de data (a primeira é a mais recente).
    historicoLesoes: InjuryRecord[];
    situacaoCadastral: "ATIVO" | "INATIVO";
    proprietario: AccountRef;
    // Omitido enquanto nenhum atleta for vinculado.
    atleta?: LinkedRef;
    // Lista do DD, com no máximo um treinador por regra de negócio.
    treinadores: LinkedRef[];
    planoAtual?: CurrentPlanRef;
    avaliacoes: {
        _id: ObjectId;
        codigo: number;
        data: string;
        treinador: {_id: string; codigo: number; nome: string};
    }[];
    criadoEm: Date;
    atualizadoEm: Date;
};

// Itens das listas resumidas mantidas por esta feature (DD 5.2). São a fonte
// única desses formatos: GuardianDocument e TrainerDocument (authentication)
// os usam nas listas 'cavalos' e 'clientes'.

// Projeção lida pela lista de cavalos (só a primeira imagem).
export type HorseListSource = Pick<
    HorseDocument,
    | "_id"
    | "nome"
    | "imagens"
    | "modalidade"
    | "proprietario"
    | "atleta"
    | "treinadores"
    | "criadoEm"
>;

// Item de treinadores.cavalos.
export type TrainerHorseRef = {_id: ObjectId; codigo: string; nome: string};

// Item de responsaveis.cavalos.
export type GuardianHorseRef = TrainerHorseRef & {
    responsabilidades: HorseResponsibility[];
};

// Campos simples, informados no cadastro e alteráveis na edição.
export type HorseFieldsInput = {
    codigo: string;
    nome: string;
    dataNascimento: string;
    raca: string;
    pelagem: string;
    sexo: HorseSex;
    modalidadeId: ObjectId;
};

// Listas de saúde e de lesões.
export type HorseHealthLists = {
    limitacoesFisicas: string[];
    observacoesSaude: string[];
    historicoLesoes: InjuryRecord[];
};

export type HorseRegistrationInput = HorseFieldsInput & HorseHealthLists & {
    responsabilidades: HorseResponsibility[];
};

// Inclusões e remoções aplicadas sobre a lista gravada no momento da
// edição, para não descartar o que outra pessoa incluiu nesse meio-tempo.
export type ListChanges<T> = {adicionar: T[]; remover: T[]};

export type HorseHealthChanges = {
    [K in keyof HorseHealthLists]: ListChanges<HorseHealthLists[K][number]>;
};

// Apenas os campos enviados são alterados.
export type HorseUpdateInput = {
    id: ObjectId;
    changes: Partial<HorseFieldsInput> & Partial<HorseHealthChanges>;
};

// E-mails já normalizados; o campo ausente mantém o vínculo atual.
export type HorseLinksInput = {
    id: ObjectId;
    emailAtleta?: string;
    emailTreinador?: string;
};

// Vínculo que o proprietário pode desfazer.
export type HorseLinkKind = "ATLETA" | "TREINADOR";

export type HorseUnlinkInput = {id: ObjectId; vinculo: HorseLinkKind};

export type HorseListOrder = "A_Z" | "Z_A" | "MAIS_RECENTES" | "MAIS_ANTIGOS";

// 'busca' filtra pelo nome do cavalo (RF04014); ausente lista todos.
export type HorseListInput = {ordenacao: HorseListOrder; busca?: string};

export type HorseRegistrationResult = {
    id: string;
    codigo: string;
    nome: string;
};

export type HorseAge = {anos: number; meses: number};

export type HorseImageContentType = "image/jpeg" | "image/png";

// Formato enviado ao app: caminho (formato do DD) e URL assinada de leitura.
export type HorseImageView = {
    caminho: string;
    url: string;
};

export type HorseImageUploadInput = {
    id: ObjectId;
    contentType: HorseImageContentType;
};

// Usado para confirmar o envio e para remover uma imagem.
export type HorseImageFileInput = {
    id: ObjectId;
    caminho: string;
};

export type HorseImageUploadResult = {
    caminho: string;
    uploadUrl: string;
    headers: Record<string, string>;
};

// Referência enviada ao app: o ObjectId vira string.
export type RefView = {id: string; codigo: number; nome: string};

// Campos comuns aos cards da lista de cavalos.
type HorseCardBase = {
    id: string;
    nome: string;
    // Primeira imagem do cavalo, ou null se não houver.
    foto: HorseImageView | null;
    modalidade: RefView | null;
    // Relação de quem consulta: PROPRIETARIO e/ou ATLETA, ou TREINADOR.
    responsabilidades: HorseRelation[];
    // Início do vínculo de quem consulta (ISO), base da ordenação por data.
    vinculadoEm: string;
};

export type GuardianHorseCard = HorseCardBase & {treinador: RefView | null};

export type TrainerHorseCard = HorseCardBase & {proprietario: RefView};

export type HorseListResult =
    | {tipoConta: "RESPONSAVEL"; cavalos: GuardianHorseCard[]}
    | {tipoConta: "TREINADOR"; cavalos: TrainerHorseCard[]};

// Inclusão de um item em uma das listas de saúde, só pelo proprietário.
// 'item' é texto nas duas primeiras listas e lesão na última.
type HealthEntryOf<K extends keyof HorseHealthLists> = {
    lista: K;
    item: HorseHealthLists[K][number];
};

export type HorseHealthEntryInput = {id: ObjectId} & {
    [K in keyof HorseHealthLists]: HealthEntryOf<K>;
}[keyof HorseHealthLists];

// Botão do card do treino do dia: o atleta inicia; os demais visualizam.
export type DayTrainingAction = "INICIAR" | "VER";

// Situação do treino de hoje, explícita para o app não deduzi-la.
// CONCLUIDO: status REALIZADO ou PARCIAL (o treino foi feito; 'status'
// traz o detalhe). PENDENTE: qualquer outro, inclusive NAO_REALIZADO. Só os
// registros de hoje aparecem, então um treino de outro dia nunca é exibido.
export type DayTrainingSituation = "SEM_TREINO" | "PENDENTE" | "CONCLUIDO";

// Card "Treino do dia" da aba "Plano atual".
export type HorseDayTraining = {
    registroId: string;
    nomeTreino: string;
    nomePlano: string;
    duracaoMinutos: number;
    // Quem aparece no card: o atleta para o treinador; o treinador para o
    // proprietário e para o atleta. 'nome' é null se o registro não a tiver.
    pessoa: {papel: "ATLETA" | "TREINADOR"; nome: string | null};
    status: "PLANEJADO" | "REALIZADO" | "PARCIAL" | "NAO_REALIZADO";
};

export type HorseDayTrainingState =
    | {situacao: "SEM_TREINO"; treino: null}
    | {situacao: "PENDENTE" | "CONCLUIDO"; treino: HorseDayTraining};

// Aba "Plano atual": plano ATIVO e o treino de hoje desse plano.
export type HorseCurrentPlanView = {
    id: string;
    codigo: number;
    titulo: string;
    dataInicio: string;
    dataFim: string;
    treinoDoDia: HorseDayTrainingState;
};

// Card da aba "Avaliações" (resumo em cavalos.avaliacoes).
export type HorseEvaluationCard = {
    id: string;
    codigo: number;
    data: string;
    treinador: RefView;
};

// Ações que o app exibe. Calculadas pelas mesmas regras que as callables
// conferem (HORSE_RULES), então esconder o botão nunca é a única proteção.
export type HorseProfilePermissions = {
    // Campos, imagens e remoção de itens de saúde (updateHorse e imagens).
    editar: boolean;
    adicionarSaude: boolean;
    excluir: boolean;
    gerenciarVinculos: boolean;
    criarAvaliacao: boolean;
    acaoTreino: DayTrainingAction;
};

// Perfil do cavalo: cabeçalho e as três abas (Dados, Plano atual e
// Avaliações) em uma resposta. Também é o retorno das edições feitas no
// perfil, para o app substituir o estado sem consultar de novo.
export type HorseProfile = {
    id: string;
    // Microchip: só o proprietário recebe; null para atleta e treinador.
    codigo: string | null;
    nome: string;
    // A primeira é a foto do cabeçalho.
    imagens: HorseImageView[];
    dataNascimento: string;
    // Calculada no momento da consulta.
    idade: HorseAge;
    raca: string;
    pelagem: string;
    sexo: HorseSex;
    modalidade: RefView | null;
    limitacoesFisicas: string[];
    observacoesSaude: string[];
    // Ordem decrescente de data.
    historicoLesoes: InjuryRecord[];
    proprietario: RefView;
    atleta: RefView | null;
    // No máximo um por regra de negócio.
    treinador: RefView | null;
    // Relação de quem consulta: PROPRIETARIO e/ou ATLETA, ou TREINADOR.
    responsabilidades: HorseRelation[];
    permissoes: HorseProfilePermissions;
    // null quando o cavalo não tem plano ATIVO.
    planoAtual: HorseCurrentPlanView | null;
    // Ordem cronológica decrescente (RF06003).
    avaliacoes: HorseEvaluationCard[];
    atualizadoEm: string;
};
