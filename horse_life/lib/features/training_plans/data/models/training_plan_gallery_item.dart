// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição da descrição opcional no item de treinamento para
// exibição nos cards da visualização do plano de treinamento.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição do construtor fromTrainingDraft para conversão de
// treinamentos criados na sessão em itens da galeria do plano.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modelo imutável dos treinamentos listados na galeria
// de seleção do cadastro de planos de treinamento.
// -----------------------------------------------------------------------------

import '../../../trainings/application/states/training_registration_draft.dart';

/// Representa um treinamento retornado pela galeria do plano de treinamento
/// conforme contrato em `docs/contrato_planos.md`.
final class TrainingPlanGalleryItem {
  const TrainingPlanGalleryItem({
    required this.id,
    required this.code,
    required this.title,
    required this.estimatedDurationMinutes,
    this.description,
    this.exerciseNames = const [],
  });

  /// Constrói um item da galeria imediatamente após a criação de um treinamento
  /// na mesma sessão.
  factory TrainingPlanGalleryItem.fromTrainingDraft(
    TrainingRegistrationDraft draft, {
    String? id,
    int? code,
  }) {
    final trimmedTitle = draft.title.trim();
    final trimmedDescription = draft.description.trim();
    return TrainingPlanGalleryItem(
      id: id ?? 'local-${trimmedTitle.toLowerCase()}',
      code: code ?? 0,
      title: trimmedTitle,
      estimatedDurationMinutes: draft.estimatedDurationMinutes ?? 0,
      description: trimmedDescription.isEmpty ? null : trimmedDescription,
      exerciseNames: draft.selectedExercises
          .map((exercise) => exercise.name.trim())
          .where((name) => name.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String id;
  final int code;
  final String title;
  final int estimatedDurationMinutes;
  final String? description;
  final List<String> exerciseNames;

  String get formattedDuration => '$estimatedDurationMinutes min';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingPlanGalleryItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          title == other.title &&
          estimatedDurationMinutes == other.estimatedDurationMinutes;

  @override
  int get hashCode =>
      Object.hash(id, code, title, estimatedDurationMinutes);
}
