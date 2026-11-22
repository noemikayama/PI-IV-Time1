// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Expansão do contrato do repositório com consulta, edição e
// cancelamento do plano de treinamento, além do suporte local em memória.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do contrato do repositório de planos de treinamento
// (listagem da galeria por cavalo e cadastro do plano), exceções tipadas
// e implementação local para testes de widget e fluxo isolado.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/trainings/data/repositories/training_exercise_gallery_repository.dart';
import 'package:horse_life/features/training_plans/application/states/training_plan_registration_draft.dart';
import '../mocks/mock_training_plan_gallery.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_detail_data.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_gallery_item.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_registration_result.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_weekday.dart';
import 'package:horse_life/features/training_plans/data/repositories/training_plan_repository.dart';

/// Implementação local em memória utilizada em testes de widget e cenários isolados.
class LocalTrainingPlanRepository implements TrainingPlanRepository {
  const LocalTrainingPlanRepository({
    this.trainings,
    this.initialPlan,
    this.shouldFailGallery = false,
    this.shouldFailCreate = false,
    this.shouldFailDetail = false,
    this.shouldFailUpdate = false,
    this.shouldFailCancel = false,
    this.createFailureMessage = 'Falha simulada no cadastro do plano.',
    this.detailFailureMessage =
        'Não foi possível carregar o plano de treinamento.',
    this.simulatedCode = 682,
    this.simulatedId = 'mock_plan_id_123',
    this.simulatedGeneratedRecordsCount = 12,
  });

  final List<TrainingPlanGalleryItem>? trainings;
  final TrainingPlanDetailData? initialPlan;
  final bool shouldFailGallery;
  final bool shouldFailCreate;
  final bool shouldFailDetail;
  final bool shouldFailUpdate;
  final bool shouldFailCancel;
  final String createFailureMessage;
  final String detailFailureMessage;
  final int simulatedCode;
  final String simulatedId;
  final int simulatedGeneratedRecordsCount;

  @override
  Future<List<TrainingPlanGalleryItem>> fetchTrainingGallery({
    required String horseId,
    String? searchQuery,
  }) async {
    if (shouldFailGallery) {
      throw const TrainingPlanGalleryFailure(
        'Não foi possível carregar a galeria de treinamentos.',
      );
    }

    final source = trainings ?? MockTrainingPlanGallery.trainings;
    final normalizedSearch = normalizeSearchText(searchQuery ?? '');

    final filtered = source.where((item) {
      if (normalizedSearch.isNotEmpty) {
        return normalizeSearchText(item.title).contains(normalizedSearch);
      }
      return true;
    }).toList();

    filtered.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return List.unmodifiable(filtered);
  }

  @override
  Future<TrainingPlanRegistrationResult> createTrainingPlan({
    required TrainingPlanRegistrationDraft draft,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    if (shouldFailCreate) {
      throw TrainingPlanRegistrationFailure(createFailureMessage);
    }

    final trimmedTitle = draft.title.trim();
    if (trimmedTitle.length < 3 || trimmedTitle.length > 80) {
      throw const TrainingPlanRegistrationFailure(
        'O título deve ter entre 3 e 80 caracteres.',
      );
    }

    final trimmedObjective = draft.objective.trim();
    if (trimmedObjective.isEmpty || trimmedObjective.length > 1000) {
      throw const TrainingPlanRegistrationFailure(
        'O objetivo deve ter entre 1 e 1000 caracteres.',
      );
    }

    if (draft.horse == null || draft.horse!.id.trim().isEmpty) {
      throw const TrainingPlanRegistrationFailure(
        'Selecione um cavalo para o plano.',
      );
    }

    if (draft.startDate == null || draft.endDate == null) {
      throw const TrainingPlanRegistrationFailure(
        'Informe as datas de início e fim do plano.',
      );
    }

    final start = TrainingPlanRegistrationDraft.dateOnly(draft.startDate!);
    final end = TrainingPlanRegistrationDraft.dateOnly(draft.endDate!);
    if (end.isBefore(start)) {
      throw const TrainingPlanRegistrationFailure(
        'A data de fim não pode ser anterior à data de início.',
      );
    }

    if (end.isAfter(TrainingPlanRegistrationDraft.maxEndDateFor(start))) {
      throw const TrainingPlanRegistrationFailure(
        'O plano pode durar no máximo 12 meses.',
      );
    }

    if (!draft.trainingsByDay.values.any((item) => item != null)) {
      throw const TrainingPlanRegistrationFailure(
        'Escolha um treino para pelo menos um dia da semana.',
      );
    }

    return TrainingPlanRegistrationResult(
      id: simulatedId,
      code: simulatedCode,
      status: 'ATIVO',
      startDate: TrainingPlanRegistrationDraft.formatYmd(start),
      endDate: TrainingPlanRegistrationDraft.formatYmd(end),
      generatedRecordsCount: simulatedGeneratedRecordsCount,
    );
  }

  @override
  Future<TrainingPlanDetailData> getTrainingPlan(String planId) async {
    if (shouldFailDetail) {
      throw TrainingPlanDetailFailure(detailFailureMessage);
    }

    if (initialPlan != null) {
      return initialPlan!;
    }

    return TrainingPlanDetailData(
      id: planId,
      code: simulatedCode,
      title: 'Condicionamento para percursos de 1,00 m',
      objective: 'Ganhar condicionamento para percursos de 1,00 m',
      startDate: DateTime(2026, 11, 23),
      endDate: DateTime(2027, 1, 31),
      horse: const TrainerLinkedHorse(id: 'horse-1', name: 'Calvino'),
      trainerId: 'trainer-1',
      trainerName: 'Carlos Mendes',
      status: TrainingPlanStatus.active,
      trainingsByDay: {
        TrainingPlanWeekday.monday: MockTrainingPlanGallery.trainings[1],
        TrainingPlanWeekday.wednesday: MockTrainingPlanGallery.trainings[0],
        TrainingPlanWeekday.friday: MockTrainingPlanGallery.trainings[2],
      },
    );
  }

  @override
  Future<TrainingPlanDetailData> updateTrainingPlan(
    String planId,
    TrainingPlanUpdate update,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    if (shouldFailUpdate) {
      throw const TrainingPlanDetailFailure(
        'Não foi possível atualizar o plano de treinamento.',
      );
    }

    final trimmedTitle = update.title.trim();
    if (trimmedTitle.length < 3 || trimmedTitle.length > 80) {
      throw const TrainingPlanDetailFailure(
        'O título deve ter entre 3 e 80 caracteres.',
      );
    }

    final trimmedObjective = update.objective.trim();
    if (trimmedObjective.isEmpty || trimmedObjective.length > 1000) {
      throw const TrainingPlanDetailFailure(
        'O objetivo deve ter entre 1 e 1000 caracteres.',
      );
    }

    if (update.horse.id.trim().isEmpty) {
      throw const TrainingPlanDetailFailure(
        'Selecione um cavalo para o plano.',
      );
    }

    final start = TrainingPlanRegistrationDraft.dateOnly(update.startDate);
    final end = TrainingPlanRegistrationDraft.dateOnly(update.endDate);
    if (end.isBefore(start)) {
      throw const TrainingPlanDetailFailure(
        'A data de fim não pode ser anterior à data de início.',
      );
    }
    if (end.isAfter(TrainingPlanRegistrationDraft.maxEndDateFor(start))) {
      throw const TrainingPlanDetailFailure(
        'O plano pode durar no máximo 12 meses.',
      );
    }

    if (!update.trainingsByDay.values.any((item) => item != null)) {
      throw const TrainingPlanDetailFailure(
        'Escolha um treino para pelo menos um dia da semana.',
      );
    }

    final draftForSchedule = TrainingPlanRegistrationDraft(
      startDate: start,
      endDate: end,
      trainingsByDay: update.trainingsByDay,
    );
    if (!draftForSchedule.hasAnyScheduledOccurrenceInPeriod) {
      throw const TrainingPlanDetailFailure(
        'Nenhum dia do período escolhido tem treino. Ajuste as datas ou os dias da semana.',
      );
    }

    final base = await getTrainingPlan(planId);
    return update.applyTo(base);
  }

  @override
  Future<TrainingPlanDetailData> cancelTrainingPlan(String planId) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    if (shouldFailCancel) {
      throw const TrainingPlanDetailFailure(
        'Não foi possível cancelar o plano de treinamento.',
      );
    }

    final base = await getTrainingPlan(planId);
    if (!base.isActive) {
      throw const TrainingPlanDetailFailure(
        'Apenas planos ativos podem ser cancelados.',
      );
    }

    return base.copyWith(status: TrainingPlanStatus.canceled);
  }
}
