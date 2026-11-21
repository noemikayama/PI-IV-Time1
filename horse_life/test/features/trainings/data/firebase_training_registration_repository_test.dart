// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes unitários do FirebaseTrainingRegistrationRepository,
// cobrindo serialização de sumExerciseDurations e registerTraining, validações
// do contrato e mapeamento de erros FirebaseFunctionsException.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/trainings/application/states/training_registration_draft.dart';
import 'package:horse_life/features/trainings/data/models/training_exercise_item.dart';
import 'package:horse_life/features/trainings/data/repositories/firebase_training_registration_repository.dart';
import 'package:horse_life/features/trainings/data/repositories/training_registration_repository.dart';

void main() {
  const exercise1 = TrainingExerciseItem(
    id: '66e1a0c2f1b2c3d4e5f6c011',
    name: 'Aquecimento ao passo',
    estimatedDurationMinutes: 10,
    exerciseType: ExerciseType.generic,
  );
  const exercise2 = TrainingExerciseItem(
    id: '66e1a0c2f1b2c3d4e5f6c010',
    name: 'Transições trote-galope',
    estimatedDurationMinutes: 20,
    exerciseType: ExerciseType.specific,
  );

  test(
    'sumExerciseDurations sends exercise ids in order and parses duracaoTotalMinutos',
    () async {
      Map<String, Object?>? capturedPayload;

      final repository = FirebaseTrainingRegistrationRepository(
        sumExerciseDurations: (payload) async {
          capturedPayload = payload;
          return {'duracaoTotalMinutos': 30};
        },
      );

      final total = await repository.sumExerciseDurations(
        exercises: const [exercise1, exercise2],
      );

      expect(capturedPayload, {
        'exercicios': ['66e1a0c2f1b2c3d4e5f6c011', '66e1a0c2f1b2c3d4e5f6c010'],
      });
      expect(total, 30);
    },
  );

  test(
    'registerTraining serializes contract payload and returns parsed result',
    () async {
      Map<String, Object?>? capturedPayload;

      final repository = FirebaseTrainingRegistrationRepository(
        registerTraining: (payload) async {
          capturedPayload = payload;
          return {
            'id': '66e1a0c2f1b2c3d4e5f6d001',
            'codigo': 42,
            'titulo': 'Trabalho de transições',
          };
        },
      );

      final result = await repository.registerTraining(
        draft: const TrainingRegistrationDraft(
          title: '  Trabalho de transições  ',
          description: '  Sessão focada em equilíbrio.  ',
          selectedExercises: [exercise1, exercise2],
          guidelines: ['  Encerrar com 5 minutos de passo  '],
          estimatedDurationMinutes: 45,
        ),
      );

      expect(capturedPayload, {
        'titulo': 'Trabalho de transições',
        'descricao': 'Sessão focada em equilíbrio.',
        'exercicios': ['66e1a0c2f1b2c3d4e5f6c011', '66e1a0c2f1b2c3d4e5f6c010'],
        'orientacoes': ['Encerrar com 5 minutos de passo'],
        'duracaoEstimadaMinutos': 45,
      });
      expect(result.id, '66e1a0c2f1b2c3d4e5f6d001');
      expect(result.code, 42);
      expect(result.title, 'Trabalho de transições');
    },
  );

  test(
    'registerTraining validates bounds and maps FirebaseFunctionsException',
    () async {
      final repository = FirebaseTrainingRegistrationRepository(
        registerTraining: (_) async {
          throw FirebaseFunctionsException(
            code: 'not-found',
            message: 'Exercício não encontrado.',
          );
        },
      );

      expect(
        () => repository.registerTraining(
          draft: const TrainingRegistrationDraft(
            title: 'Treino válido',
            selectedExercises: [],
            estimatedDurationMinutes: 30,
          ),
        ),
        throwsA(isA<TrainingRegistrationFailure>()),
      );

      expect(
        () => repository.registerTraining(
          draft: const TrainingRegistrationDraft(
            title: 'Treino válido',
            selectedExercises: [exercise1],
            guidelines: [],
            estimatedDurationMinutes: 30,
          ),
        ),
        throwsA(isA<TrainingRegistrationFailure>()),
      );

      expect(
        () => repository.registerTraining(
          draft: const TrainingRegistrationDraft(
            title: 'Treino válido',
            selectedExercises: [exercise1],
            guidelines: ['Orientação 1'],
            estimatedDurationMinutes: 5,
          ),
        ),
        throwsA(isA<TrainingRegistrationFailure>()),
      );

      expect(
        () => repository.registerTraining(
          draft: const TrainingRegistrationDraft(
            title: 'Treino válido',
            selectedExercises: [exercise1],
            guidelines: ['Orientação 1'],
            estimatedDurationMinutes: 500,
          ),
        ),
        throwsA(isA<TrainingRegistrationFailure>()),
      );

      expect(
        () => repository.registerTraining(
          draft: const TrainingRegistrationDraft(
            title: 'Treino válido',
            selectedExercises: [exercise1],
            guidelines: ['Orientação 1'],
            estimatedDurationMinutes: 30,
          ),
        ),
        throwsA(
          isA<TrainingRegistrationFailure>().having(
            (e) => e.message,
            'message',
            'Exercício não encontrado.',
          ),
        ),
      );
    },
  );
}
