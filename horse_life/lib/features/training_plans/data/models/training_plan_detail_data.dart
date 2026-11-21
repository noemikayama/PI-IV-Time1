// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos modelos imutáveis de visualização, permissões,
// status e atualização do plano de treinamento.
// -----------------------------------------------------------------------------

import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../../application/states/training_plan_registration_draft.dart';
import 'training_plan_gallery_item.dart';
import 'training_plan_weekday.dart';

/// Situação operacional do plano de treinamento.
enum TrainingPlanStatus {
  draft(apiKey: 'RASCUNHO', label: 'Rascunho'),
  active(apiKey: 'ATIVO', label: 'Ativo'),
  completed(apiKey: 'CONCLUIDO', label: 'Concluído'),
  canceled(apiKey: 'CANCELADO', label: 'Cancelado');

  const TrainingPlanStatus({required this.apiKey, required this.label});

  final String apiKey;
  final String label;

  /// Converte o código retornado pela API ou rótulo textual para o enum.
  static TrainingPlanStatus fromApi(String? raw) {
    final normalized = raw?.trim().toUpperCase() ?? '';
    return switch (normalized) {
      'RASCUNHO' => TrainingPlanStatus.draft,
      'ATIVO' => TrainingPlanStatus.active,
      'CONCLUIDO' || 'CONCLUÍDO' => TrainingPlanStatus.completed,
      'CANCELADO' => TrainingPlanStatus.canceled,
      _ => TrainingPlanStatus.active,
    };
  }
}

/// Retrato completo do plano de treinamento exibido na tela de visualização.
final class TrainingPlanDetailData {
  const TrainingPlanDetailData({
    required this.id,
    required this.code,
    required this.title,
    required this.objective,
    required this.startDate,
    required this.endDate,
    required this.horse,
    required this.trainerId,
    required this.trainerName,
    required this.status,
    required this.trainingsByDay,
    this.isOwner,
  });

  final String id;
  final int code;
  final String title;
  final String objective;
  final DateTime startDate;
  final DateTime endDate;
  final TrainerLinkedHorse horse;
  final String trainerId;
  final String trainerName;
  final TrainingPlanStatus status;
  final Map<TrainingPlanWeekday, TrainingPlanGalleryItem> trainingsByDay;
  final bool? isOwner;

  /// Indica se o plano encontra-se ativo e passível de cancelamento.
  bool get isActive => status == TrainingPlanStatus.active;

  /// Treinamentos selecionados ordenados de segunda a domingo.
  List<MapEntry<TrainingPlanWeekday, TrainingPlanGalleryItem>>
  get selectedWeekdayEntries => List.unmodifiable([
    for (final weekday in TrainingPlanWeekday.values)
      if (trainingsByDay[weekday] case final training?)
        MapEntry(weekday, training),
  ]);

  /// Define se o usuário atual é o treinador proprietário deste plano.
  bool canManage({String? currentUserId, required bool isTrainer}) {
    if (!isTrainer) return false;
    if (isOwner != null) return isOwner!;

    final normalizedCurrentUserId = currentUserId?.trim() ?? '';
    final normalizedTrainerId = trainerId.trim();
    if (normalizedCurrentUserId.isNotEmpty && normalizedTrainerId.isNotEmpty) {
      return normalizedCurrentUserId == normalizedTrainerId;
    }
    return isTrainer;
  }

  TrainingPlanDetailData copyWith({
    String? id,
    int? code,
    String? title,
    String? objective,
    DateTime? startDate,
    DateTime? endDate,
    TrainerLinkedHorse? horse,
    String? trainerId,
    String? trainerName,
    TrainingPlanStatus? status,
    Map<TrainingPlanWeekday, TrainingPlanGalleryItem>? trainingsByDay,
    bool? isOwner,
  }) {
    return TrainingPlanDetailData(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      objective: objective ?? this.objective,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      horse: horse ?? this.horse,
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      status: status ?? this.status,
      trainingsByDay: trainingsByDay != null
          ? Map.unmodifiable(trainingsByDay)
          : this.trainingsByDay,
      isOwner: isOwner ?? this.isOwner,
    );
  }
}

/// Estado final consolidado pelo formulário de edição do plano de treinamento.
final class TrainingPlanUpdate {
  const TrainingPlanUpdate({
    required this.title,
    required this.objective,
    required this.startDate,
    required this.endDate,
    required this.horse,
    required this.trainingsByDay,
  });

  final String title;
  final String objective;
  final DateTime startDate;
  final DateTime endDate;
  final TrainerLinkedHorse horse;
  final Map<TrainingPlanWeekday, TrainingPlanGalleryItem?> trainingsByDay;

  /// Serializa os dados editados no contrato esperado pelo backend.
  Map<String, Object?> toJson(String id) {
    return {
      'planoId': id.trim(),
      'titulo': title.trim(),
      'objetivo': objective.trim(),
      'cavaloId': horse.id.trim(),
      'dataInicio': TrainingPlanRegistrationDraft.formatYmd(startDate),
      'dataFim': TrainingPlanRegistrationDraft.formatYmd(endDate),
      'treinosPorDia': {
        for (final weekday in TrainingPlanWeekday.values)
          weekday.apiKey: _normalizeOptionalId(trainingsByDay[weekday]?.id),
      },
    };
  }

  /// Aplica as alterações editadas sobre a visualização atual do plano.
  TrainingPlanDetailData applyTo(TrainingPlanDetailData base) {
    final cleanedTrainings = <TrainingPlanWeekday, TrainingPlanGalleryItem>{
      for (final entry in trainingsByDay.entries)
        if (entry.value != null) entry.key: entry.value!,
    };

    return base.copyWith(
      title: title.trim(),
      objective: objective.trim(),
      startDate: TrainingPlanRegistrationDraft.dateOnly(startDate),
      endDate: TrainingPlanRegistrationDraft.dateOnly(endDate),
      horse: horse,
      trainingsByDay: cleanedTrainings,
    );
  }

  String? _normalizeOptionalId(String? rawId) {
    final trimmed = rawId?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
