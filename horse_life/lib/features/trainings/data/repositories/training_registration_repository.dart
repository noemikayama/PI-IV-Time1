// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação defensiva exigindo ao menos uma orientação e duração
// estimada não inferior à soma dos exercícios selecionados.
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do contrato de persistência e cálculo de duração de
// treinamentos, exceção tipada de domínio e implementação local para testes.
// -----------------------------------------------------------------------------

import '../../application/states/training_registration_draft.dart';
import '../models/training_exercise_item.dart';
import '../models/training_registration_result.dart';

export '../models/training_registration_result.dart';

/// Contrato que mantém os detalhes das Cloud Functions fora das telas de
/// cadastro de treinamentos.
abstract interface class TrainingRegistrationRepository {
  /// Calcula a soma das durações padrão dos exercícios selecionados.
  Future<int> sumExerciseDurations({
    required List<TrainingExerciseItem> exercises,
  });

  /// Envia o rascunho consolidado do treinamento para persistência no backend.
  Future<TrainingRegistrationResult> registerTraining({
    required TrainingRegistrationDraft draft,
  });
}

/// Erro seguro para apresentação na interface durante operações de treinamento.
final class TrainingRegistrationFailure implements Exception {
  const TrainingRegistrationFailure(this.message);

  const TrainingRegistrationFailure.connection()
    : message = 'Erro de conexão com o servidor';

  final String message;

  @override
  String toString() => message;
}

/// Implementação local em memória utilizada em testes de widget e ambientes
/// sem conexão com Cloud Functions.
class LocalTrainingRegistrationRepository
    implements TrainingRegistrationRepository {
  const LocalTrainingRegistrationRepository({
    this.shouldFail = false,
    this.failureMessage = 'Falha simulada no cadastro do treinamento.',
    this.simulatedCode = 1,
    this.simulatedId = 'mock_training_id_123',
  });

  final bool shouldFail;
  final String failureMessage;
  final int simulatedCode;
  final String simulatedId;

  @override
  Future<int> sumExerciseDurations({
    required List<TrainingExerciseItem> exercises,
  }) async {
    return exercises.fold<int>(
      0,
      (total, exercise) => total + exercise.estimatedDurationMinutes,
    );
  }

  @override
  Future<TrainingRegistrationResult> registerTraining({
    required TrainingRegistrationDraft draft,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    if (shouldFail) {
      throw TrainingRegistrationFailure(failureMessage);
    }

    final trimmedTitle = draft.title.trim();
    if (trimmedTitle.length < 3 || trimmedTitle.length > 80) {
      throw const TrainingRegistrationFailure(
        'O título deve ter entre 3 e 80 caracteres.',
      );
    }

    if (draft.selectedExercises.isEmpty) {
      throw const TrainingRegistrationFailure(
        'Selecione pelo menos um exercício para cadastrar o treinamento.',
      );
    }

    final cleanGuidelines = draft.guidelines
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (cleanGuidelines.isEmpty) {
      throw const TrainingRegistrationFailure(
        'Adicione pelo menos uma orientação para cadastrar o treinamento.',
      );
    }

    final duration = draft.estimatedDurationMinutes;
    if (duration == null || duration < 1 || duration > 480) {
      throw const TrainingRegistrationFailure(
        'A duração estimada deve ser um número inteiro entre 1 e 480 minutos.',
      );
    }

    final totalExercisesDuration = draft.selectedExercises.fold<int>(
      0,
      (total, exercise) => total + exercise.estimatedDurationMinutes,
    );
    if (duration < totalExercisesDuration) {
      throw TrainingRegistrationFailure(
        'A duração estimada não pode ser menor que a soma dos exercícios ($totalExercisesDuration min).',
      );
    }

    return TrainingRegistrationResult(
      id: simulatedId,
      code: simulatedCode,
      title: trimmedTitle,
    );
  }
}
