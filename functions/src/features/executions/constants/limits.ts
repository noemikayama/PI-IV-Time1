// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Limites da execução, do feedback e da lista de pendentes.
// -----------------------------------------------------------------------------

// Mesmo limite da duração estimada do treinamento.
export const MAX_EFFECTIVE_MINUTES = 480;

// Percepção de desempenho: 10 é o desempenho máximo.
export const MIN_PERCEPTION = 1;
export const MAX_PERCEPTION = 10;

export const MAX_DIFFICULTIES_LENGTH = 1000;
export const MAX_EXERCISE_NOTE_LENGTH = 500;
export const MAX_COMMENT_LENGTH = 1000;

// Listas de textos (observações, dificuldades identificadas e orientações)
// seguem o limite das orientações do treinamento.
export const MAX_TEXT_ITEMS = 30;
export const MAX_TEXT_ITEM_LENGTH = 500;

// Tamanho da lista de execuções que esperam feedback.
export const PENDING_FEEDBACKS_LIMIT = 50;
