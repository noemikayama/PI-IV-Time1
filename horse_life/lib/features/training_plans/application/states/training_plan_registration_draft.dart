// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição de utilitários de manipulação por dia da semana e validação
// de ocorrência programada dentro do período do plano no TrainingPlanRegistrationDraft.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do estado imutável de rascunho para o fluxo de cadastro
// de planos de treinamento, contemplando título, objetivo, cavalo vinculado,
// avaliação opcional, período (data de início e fim) e mapa semanal.
// -----------------------------------------------------------------------------

import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../../data/models/training_plan_gallery_item.dart';
import '../../data/models/training_plan_weekday.dart';

/// Estado consolidado e imutável trafegado entre as etapas do cadastro de
/// planos de treinamento.
final class TrainingPlanRegistrationDraft {
  const TrainingPlanRegistrationDraft({
    this.title = '',
    this.objective = '',
    this.horse,
    this.evaluationId,
    this.startDate,
    this.endDate,
    this.trainingsByDay = const {},
  });

  final String title;
  final String objective;
  final TrainerLinkedHorse? horse;
  final String? evaluationId;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<TrainingPlanWeekday, TrainingPlanGalleryItem?> trainingsByDay;

  /// Normaliza uma instância [DateTime] removendo horas, minutos e segundos.
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Soma meses respeitando o último dia válido do mês de destino.
  static DateTime addMonths(DateTime date, int months) {
    final firstOfTargetMonth = DateTime(date.year, date.month + months, 1);
    final lastDayOfMonth = DateTime(
      firstOfTargetMonth.year,
      firstOfTargetMonth.month + 1,
      0,
    ).day;
    final clampedDay = date.day <= lastDayOfMonth ? date.day : lastDayOfMonth;
    return DateTime(
      firstOfTargetMonth.year,
      firstOfTargetMonth.month,
      clampedDay,
    );
  }

  /// Data limite inclusiva para a data de fim (menor que 12 meses a partir de [startDate]).
  static DateTime maxEndDateFor(DateTime startDate) {
    final normalizedStart = dateOnly(startDate);
    final exclusiveLimit = addMonths(normalizedStart, 12);
    return DateTime(
      exclusiveLimit.year,
      exclusiveLimit.month,
      exclusiveLimit.day - 1,
    );
  }

  /// Formata uma data no padrão AAAA-MM-DD esperado pelo backend.
  static String formatYmd(DateTime date) {
    final normalized = dateOnly(date);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  TrainingPlanRegistrationDraft withTitle(String title) {
    return TrainingPlanRegistrationDraft(
      title: title,
      objective: objective,
      horse: horse,
      evaluationId: evaluationId,
      startDate: startDate,
      endDate: endDate,
      trainingsByDay: trainingsByDay,
    );
  }

  TrainingPlanRegistrationDraft withObjective(String objective) {
    return TrainingPlanRegistrationDraft(
      title: title,
      objective: objective,
      horse: horse,
      evaluationId: evaluationId,
      startDate: startDate,
      endDate: endDate,
      trainingsByDay: trainingsByDay,
    );
  }

  TrainingPlanRegistrationDraft withHorse(TrainerLinkedHorse? horse) {
    final shouldResetDependentFields = this.horse?.id != horse?.id;
    return TrainingPlanRegistrationDraft(
      title: title,
      objective: objective,
      horse: horse,
      evaluationId: shouldResetDependentFields ? null : evaluationId,
      startDate: startDate,
      endDate: endDate,
      trainingsByDay: shouldResetDependentFields ? const {} : trainingsByDay,
    );
  }

  TrainingPlanRegistrationDraft withStartDate(DateTime? startDate) {
    final normalizedStart = startDate != null ? dateOnly(startDate) : null;
    DateTime? adjustedEndDate = endDate != null ? dateOnly(endDate!) : null;
    if (normalizedStart != null && adjustedEndDate != null) {
      final maxEnd = maxEndDateFor(normalizedStart);
      if (adjustedEndDate.isBefore(normalizedStart) ||
          adjustedEndDate.isAfter(maxEnd)) {
        adjustedEndDate = null;
      }
    }

    return TrainingPlanRegistrationDraft(
      title: title,
      objective: objective,
      horse: horse,
      evaluationId: evaluationId,
      startDate: normalizedStart,
      endDate: adjustedEndDate,
      trainingsByDay: trainingsByDay,
    );
  }

  TrainingPlanRegistrationDraft withEndDate(DateTime? endDate) {
    return TrainingPlanRegistrationDraft(
      title: title,
      objective: objective,
      horse: horse,
      evaluationId: evaluationId,
      startDate: startDate,
      endDate: endDate != null ? dateOnly(endDate) : null,
      trainingsByDay: trainingsByDay,
    );
  }

  TrainingPlanRegistrationDraft withTrainingsByDay(
    Map<TrainingPlanWeekday, TrainingPlanGalleryItem?> trainingsByDay,
  ) {
    return TrainingPlanRegistrationDraft(
      title: title,
      objective: objective,
      horse: horse,
      evaluationId: evaluationId,
      startDate: startDate,
      endDate: endDate,
      trainingsByDay: Map.unmodifiable(trainingsByDay),
    );
  }

  /// Atualiza o treinamento selecionado para um dia específico da semana.
  TrainingPlanRegistrationDraft withTrainingForDay(
    TrainingPlanWeekday weekday,
    TrainingPlanGalleryItem? training,
  ) {
    final updated = Map<TrainingPlanWeekday, TrainingPlanGalleryItem?>.of(
      trainingsByDay,
    );
    if (training == null) {
      updated.remove(weekday);
    } else {
      updated[weekday] = training;
    }
    return withTrainingsByDay(updated);
  }

  /// Indica se ao menos um dia da semana possui um treinamento atribuído.
  bool get hasAnySelectedTraining =>
      trainingsByDay.values.any((item) => item != null);

  /// Verifica se ao menos uma data entre [startDate] e [endDate] corresponde a
  /// um dia da semana que possui treinamento atribuído.
  bool get hasAnyScheduledOccurrenceInPeriod {
    final start = startDate;
    final end = endDate;
    if (start == null || end == null) return false;

    final normalizedStart = dateOnly(start);
    final normalizedEnd = dateOnly(end);
    for (var offset = 0; offset < 7; offset++) {
      final candidate = DateTime(
        normalizedStart.year,
        normalizedStart.month,
        normalizedStart.day + offset,
      );
      if (candidate.isAfter(normalizedEnd)) break;
      final weekday = TrainingPlanWeekday.values[candidate.weekday - 1];
      if (trainingsByDay[weekday] != null) return true;
    }
    return false;
  }

  /// Entradas com treinamentos atribuídos ordenadas de segunda a domingo.
  List<MapEntry<TrainingPlanWeekday, TrainingPlanGalleryItem>>
  get selectedWeekdayEntries => List.unmodifiable([
    for (final weekday in TrainingPlanWeekday.values)
      if (trainingsByDay[weekday] case final training?)
        MapEntry(weekday, training),
  ]);
}
