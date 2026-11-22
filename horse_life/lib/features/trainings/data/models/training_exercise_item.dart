// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição dos campos opcionais code e description, método matches e
// copyWith em TrainingExerciseItem para integração com detalhes/edição de treino.
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
    this.code,
    this.description,
  });

  /// Constrói um item da galeria imediatamente após a criação de um exercício
  /// pelo fluxo de cadastro de exercícios durante a mesma sessão.
  factory TrainingExerciseItem.fromExerciseDraft(
    ExerciseRegistrationDraft draft, {
    String? id,
    int? code,
  }) {
    final trimmedName = draft.name.trim();
    final trimmedDescription = draft.description.trim();
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
      code: code,
      description: trimmedDescription.isEmpty ? null : trimmedDescription,
    );
  }

  final String id;
  final String name;
  final int estimatedDurationMinutes;
  final ExerciseType exerciseType;
  final TrainerLinkedHorse? horse;
  final int? code;
  final String? description;

  bool get isSpecific => exerciseType == ExerciseType.specific;
  bool get isGeneric => exerciseType == ExerciseType.generic;

  /// Texto formatado de tempo estimado para exibição nos cards.
  String get formattedDuration => '$estimatedDurationMinutes min';

  /// Rótulo textual do tipo de exercício conforme a prototipação.
  String get formattedType => switch (exerciseType) {
    ExerciseType.generic => 'genérico',
    ExerciseType.specific => 'específico',
  };

  /// Indica se este item representa o mesmo exercício que [other], seja pelo
  /// identificador, pelo código sequencial ou pelos metadados equivalentes.
  bool matches(TrainingExerciseItem other) {
    if (id == other.id) return true;
    if (code != null && other.code != null && code! > 0 && code == other.code) {
      return true;
    }
    return name.trim().toLowerCase() == other.name.trim().toLowerCase() &&
        exerciseType == other.exerciseType &&
        (horse?.name.trim().toLowerCase() ?? '') ==
            (other.horse?.name.trim().toLowerCase() ?? '');
  }

  TrainingExerciseItem copyWith({
    String? id,
    String? name,
    int? estimatedDurationMinutes,
    ExerciseType? exerciseType,
    TrainerLinkedHorse? horse,
    int? code,
    String? description,
  }) {
    return TrainingExerciseItem(
      id: id ?? this.id,
      name: name ?? this.name,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      exerciseType: exerciseType ?? this.exerciseType,
      horse: horse ?? this.horse,
      code: code ?? this.code,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingExerciseItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          estimatedDurationMinutes == other.estimatedDurationMinutes &&
          exerciseType == other.exerciseType &&
          horse == other.horse &&
          code == other.code &&
          description == other.description;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    estimatedDurationMinutes,
    exerciseType,
    horse,
    code,
    description,
  );
}
