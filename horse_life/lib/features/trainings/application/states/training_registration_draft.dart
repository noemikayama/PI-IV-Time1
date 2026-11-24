// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição dos getters calculados para duração total dos exercícios
// selecionados (em minutos e formatada para exibição).
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do estado imutável de rascunho para o formulário de
// cadastro de treinamentos (6 etapas), mantendo título, descrição, exercícios
// selecionados na ordem de execução, orientações e duração estimada.
// -----------------------------------------------------------------------------

import '../../data/models/training_exercise_item.dart';

/// Estado consolidado e imutável trafegado entre as 6 etapas do cadastro de
/// treinamentos.
final class TrainingRegistrationDraft {
  const TrainingRegistrationDraft({
    this.title = '',
    this.description = '',
    this.selectedExercises = const [],
    this.guidelines = const [],
    this.estimatedDurationMinutes,
  });

  final String title;
  final String description;
  final List<TrainingExerciseItem> selectedExercises;
  final List<String> guidelines;
  final int? estimatedDurationMinutes;

  /// Soma local das durações estimadas dos exercícios selecionados.
  int get totalExercisesDurationMinutes => selectedExercises.fold<int>(
    0,
    (total, exercise) => total + exercise.estimatedDurationMinutes,
  );

  /// Soma total formatada para exibição informativa na etapa de duração.
  String get formattedTotalExercisesDuration =>
      '$totalExercisesDurationMinutes min';

  TrainingRegistrationDraft withTitle(String title) {
    return TrainingRegistrationDraft(
      title: title,
      description: description,
      selectedExercises: selectedExercises,
      guidelines: guidelines,
      estimatedDurationMinutes: estimatedDurationMinutes,
    );
  }

  TrainingRegistrationDraft withDescription(String description) {
    return TrainingRegistrationDraft(
      title: title,
      description: description,
      selectedExercises: selectedExercises,
      guidelines: guidelines,
      estimatedDurationMinutes: estimatedDurationMinutes,
    );
  }

  TrainingRegistrationDraft withSelectedExercises(
    List<TrainingExerciseItem> selectedExercises,
  ) {
    return TrainingRegistrationDraft(
      title: title,
      description: description,
      selectedExercises: List.unmodifiable(selectedExercises),
      guidelines: guidelines,
      estimatedDurationMinutes: estimatedDurationMinutes,
    );
  }

  TrainingRegistrationDraft withGuidelines(List<String> guidelines) {
    return TrainingRegistrationDraft(
      title: title,
      description: description,
      selectedExercises: selectedExercises,
      guidelines: List.unmodifiable(guidelines),
      estimatedDurationMinutes: estimatedDurationMinutes,
    );
  }

  TrainingRegistrationDraft withEstimatedDurationMinutes(
    int? estimatedDurationMinutes,
  ) {
    return TrainingRegistrationDraft(
      title: title,
      description: description,
      selectedExercises: selectedExercises,
      guidelines: guidelines,
      estimatedDurationMinutes: estimatedDurationMinutes,
    );
  }
}
