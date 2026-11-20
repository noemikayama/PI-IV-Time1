// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do contrato do repositório de planos de treinamento
// (listagem da galeria por cavalo e cadastro do plano), exceções tipadas
// e implementação local para testes de widget e fluxo isolado.
// -----------------------------------------------------------------------------

import '../../../trainings/data/repositories/training_exercise_gallery_repository.dart';
import '../../application/states/training_plan_registration_draft.dart';
import '../mocks/mock_training_plan_gallery.dart';
import '../models/training_plan_gallery_item.dart';
import '../models/training_plan_registration_result.dart';

export '../models/training_plan_registration_result.dart';

/// Contrato de acesso à galeria de treinamentos e cadastro de planos.
abstract interface class TrainingPlanRepository {
  /// Lista os treinamentos do treinador compatíveis com o cavalo informado.
  Future<List<TrainingPlanGalleryItem>> fetchTrainingGallery({
    required String horseId,
    String? searchQuery,
  });

  /// Envia o plano de treinamento consolidado para criação no backend.
  Future<TrainingPlanRegistrationResult> createTrainingPlan({
    required TrainingPlanRegistrationDraft draft,
  });
}

/// Erro seguro para apresentação na interface durante consultas à galeria.
final class TrainingPlanGalleryFailure implements Exception {
  const TrainingPlanGalleryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Erro seguro para apresentação na interface durante o cadastro do plano.
final class TrainingPlanRegistrationFailure implements Exception {
  const TrainingPlanRegistrationFailure(this.message);

  const TrainingPlanRegistrationFailure.connection()
    : message = 'Erro de conexão com o servidor';

  final String message;

  @override
  String toString() => message;
}

/// Implementação local em memória utilizada em testes de widget e cenários isolados.
class LocalTrainingPlanRepository implements TrainingPlanRepository {
  const LocalTrainingPlanRepository({
    this.trainings,
    this.shouldFailGallery = false,
    this.shouldFailCreate = false,
    this.createFailureMessage = 'Falha simulada no cadastro do plano.',
    this.simulatedCode = 682,
    this.simulatedId = 'mock_plan_id_123',
    this.simulatedGeneratedRecordsCount = 12,
  });

  final List<TrainingPlanGalleryItem>? trainings;
  final bool shouldFailGallery;
  final bool shouldFailCreate;
  final String createFailureMessage;
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
}
