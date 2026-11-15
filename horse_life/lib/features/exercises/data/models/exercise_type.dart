// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do enum que representa o tipo e o nível de privacidade do
// exercício selecionado no início do fluxo de cadastro.
// -----------------------------------------------------------------------------

// Representa os dois níveis de privacidade aceitos no cadastro de exercícios.
enum ExerciseType {
  // Exercício criado exclusivamente para um único cavalo vinculado ao treinador,
  // não ficando disponível no acervo pessoal para reutilização genérica.
  specific,

  // Exercício reutilizável que integra o acervo pessoal do treinador para a
  // prescrição de treinamentos e planos futuros.
  generic;

  // Rótulo legível apresentado nos seletores da camada de apresentação.
  String get label => switch (this) {
    ExerciseType.specific => 'Específico',
    ExerciseType.generic => 'Genérico',
  };
}
