// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Remoção de import redundante do resultado de cadastro, preservando
// o comportamento do repositório simulado.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do repositório mock para testes do fluxo de cadastro
// de exercícios sem dependência de emuladores ou Cloud Functions.
// -----------------------------------------------------------------------------

import '../../application/states/exercise_registration_draft.dart';
import 'exercise_registration_repository.dart';

class MockExerciseRegistrationRepository
    implements ExerciseRegistrationRepository {
  const MockExerciseRegistrationRepository({
    this.shouldFail = false,
    this.failureMessage = 'Falha simulada no cadastro de exercício.',
    this.simulatedCode = 1,
    this.simulatedId = 'mock_exercise_id_123',
    this.simulatedFailedMediaCount = 0,
  });

  final bool shouldFail;
  final String failureMessage;
  final int simulatedCode;
  final String simulatedId;
  final int simulatedFailedMediaCount;

  @override
  Future<ExerciseRegistrationResult> registerExercise({
    required ExerciseRegistrationDraft draft,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (shouldFail) {
      throw ExerciseRegistrationFailure(failureMessage);
    }

    if (draft.guidelines.isEmpty) {
      throw const ExerciseRegistrationFailure(
        'O exercício deve conter pelo menos uma orientação.',
      );
    }

    if (draft.name.trim().length < 3 || draft.name.trim().length > 80) {
      throw const ExerciseRegistrationFailure(
        'O nome do exercício deve ter entre 3 e 80 caracteres.',
      );
    }

    final warning = simulatedFailedMediaCount > 0
        ? 'Exercício cadastrado, mas $simulatedFailedMediaCount mídia(s) não foram enviadas.'
        : null;

    return ExerciseRegistrationResult(
      id: simulatedId,
      code: simulatedCode,
      name: draft.name.trim(),
      warning: warning,
      failedMediaCount: simulatedFailedMediaCount,
    );
  }
}
