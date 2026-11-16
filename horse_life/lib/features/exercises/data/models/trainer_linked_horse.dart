// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modelo imutável que representa um cavalo vinculado ao
// treinador para seleção no cadastro de exercícios específicos.
// -----------------------------------------------------------------------------

// Identifica um animal vinculado ao treinador na prescrição de exercícios.
final class TrainerLinkedHorse {
  const TrainerLinkedHorse({
    required this.id,
    required this.name,
  });

  // Identificador único do documento do cavalo no backend e nome de exibição.
  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainerLinkedHorse &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}
