// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes unitários do FirebaseTrainingExerciseGalleryRepository,
// cobrindo serialização dos filtros de busca/cavalo e parse de exercícios
// genéricos e específicos retornados pelo backend.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/trainings/data/repositories/firebase_training_exercise_gallery_repository.dart';
import 'package:horse_life/features/trainings/data/repositories/training_exercise_gallery_repository.dart';

void main() {
  test(
    'serializes optional filters and parses generic and specific gallery items',
    () async {
      Map<String, Object?>? capturedPayload;

      final repository = FirebaseTrainingExerciseGalleryRepository(
        listExerciseGallery: (payload) async {
          capturedPayload = payload;
          return {
            'exercicios': [
              {
                'id': '66e1a0c2f1b2c3d4e5f6c011',
                'nome': 'Aquecimento ao passo',
                'duracaoPadraoMinutos': 10,
                'privacidade': 'GENERICO',
              },
              {
                'id': '66e1a0c2f1b2c3d4e5f6c010',
                'nome': 'Transições trote-galope',
                'duracaoPadraoMinutos': 20,
                'privacidade': 'ESPECIFICO',
                'cavalo': {
                  'id': '66e1a0c2f1b2c3d4e5f60050',
                  'codigo': '123123456789012',
                  'nome': 'Trovão',
                },
              },
            ],
          };
        },
      );

      final items = await repository.fetchGalleryExercises(
        searchQuery: '  trote  ',
        horseId: '66e1a0c2f1b2c3d4e5f60050',
      );

      expect(capturedPayload, {
        'busca': 'trote',
        'cavaloId': '66e1a0c2f1b2c3d4e5f60050',
      });
      expect(items, hasLength(2));

      expect(items[0].id, '66e1a0c2f1b2c3d4e5f6c011');
      expect(items[0].name, 'Aquecimento ao passo');
      expect(items[0].estimatedDurationMinutes, 10);
      expect(items[0].exerciseType, ExerciseType.generic);
      expect(items[0].horse, isNull);

      expect(items[1].id, '66e1a0c2f1b2c3d4e5f6c010');
      expect(items[1].exerciseType, ExerciseType.specific);
      expect(items[1].horse?.id, '66e1a0c2f1b2c3d4e5f60050');
      expect(items[1].horse?.name, 'Trovão');
    },
  );

  test(
    'omits busca and cavaloId when empty to load default generic gallery',
    () async {
      Map<String, Object?>? capturedPayload;

      final repository = FirebaseTrainingExerciseGalleryRepository(
        listExerciseGallery: (payload) async {
          capturedPayload = payload;
          return {'exercicios': []};
        },
      );

      final items = await repository.fetchGalleryExercises(
        searchQuery: '   ',
        horseId: '',
      );

      expect(capturedPayload, isEmpty);
      expect(items, isEmpty);
    },
  );

  test('maps FirebaseFunctionsException to TrainingGalleryFailure', () async {
    final repository = FirebaseTrainingExerciseGalleryRepository(
      listExerciseGallery: (_) async {
        throw FirebaseFunctionsException(
          code: 'permission-denied',
          message: 'Cavalo sem vínculo com o treinador.',
        );
      },
    );

    expect(
      () => repository.fetchGalleryExercises(horseId: 'invalid-horse'),
      throwsA(
        isA<TrainingGalleryFailure>().having(
          (e) => e.message,
          'message',
          'Cavalo sem vínculo com o treinador.',
        ),
      ),
    );
  });
}
