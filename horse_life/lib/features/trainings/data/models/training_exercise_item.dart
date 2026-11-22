// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modelo imutável de exercício disponível na galeria
// e na lista selecionada durante o cadastro de treinamentos.
// -----------------------------------------------------------------------------

import '../../../exercises/application/states/exercise_registration_draft.dart';
import '../../../exercises/data/models/exercise_type.dart';
import '../../../exercises/data/models/trainer_linked_horse.dart';

/// Representa um exercício exibido na galeria de seleção e na listagem do
/// treinamento, reaproveitando [ExerciseType] e [TrainerLinkedHorse].
final class TrainingExerciseItem {
  const TrainingExerciseItem({
    required this.id,
    required this.name,
    required this.estimatedDurationMinutes,
    required this.exerciseType,
    this.horse,
  });

  /// Constrói um item da galeria imediatamente após a criação de um exercício
  /// pelo fluxo de cadastro de exercícios durante a mesma sessão.
  factory TrainingExerciseItem.fromExerciseDraft(
    ExerciseRegistrationDraft draft, {
    String? id,
  }) {
    final trimmedName = draft.name.trim();
    final horse = switch (draft) {
      final SpecificExerciseRegistrationDraft specific => specific.horse,
      GenericExerciseRegistrationDraft() => null,
    };

    return TrainingExerciseItem(
      id: id ?? 'local-${trimmedName.toLowerCase()}-${horse?.id ?? 'generic'}',
      name: trimmedName,
      estimatedDurationMinutes: draft.defaultDurationMinutes ?? 0,
      exerciseType: draft.exerciseType,
      horse: horse,
    );
  }

  final String id;
  final String name;
  final int estimatedDurationMinutes;
  final ExerciseType exerciseType;
  final TrainerLinkedHorse? horse;

  bool get isSpecific => exerciseType == ExerciseType.specific;
  bool get isGeneric => exerciseType == ExerciseType.generic;

  /// Texto formatado de tempo estimado para exibição nos cards.
  String get formattedDuration => '$estimatedDurationMinutes min';

  /// Rótulo textual do tipo de exercício conforme a prototipação.
  String get formattedType => switch (exerciseType) {
    ExerciseType.generic => 'genérico',
    ExerciseType.specific => 'específico',
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingExerciseItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          estimatedDurationMinutes == other.estimatedDurationMinutes &&
          exerciseType == other.exerciseType &&
          horse == other.horse;

  @override
  int get hashCode =>
      Object.hash(id, name, estimatedDurationMinutes, exerciseType, horse);
}
