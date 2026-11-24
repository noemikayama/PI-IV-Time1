// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Inclusão de testes cobrindo resolução de identificador não numérico
// com fallback por código e garantia de exercícios não vazios.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes unitários do FirebaseTrainingDetailRepository,
// cobrindo getTrainingDetails, updateTraining, resolução de códigos via
// getExercise, validações e mapeamento de erros do backend.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_gallery_item.dart';
import 'package:horse_life/features/trainings/data/models/training_detail_data.dart';
import 'package:horse_life/features/trainings/data/models/training_exercise_item.dart';
import 'package:horse_life/features/trainings/data/repositories/firebase_training_detail_repository.dart';
import 'package:horse_life/features/trainings/data/repositories/training_detail_repository.dart';

void main() {
  test(
    'getTrainingDetails envia codigo como string e faz parse completo para treinador',
    () async {
      Map<String, Object?>? capturedPayload;

      final repository = FirebaseTrainingDetailRepository(
        getTrainingDetails: (payload) async {
          capturedPayload = payload;
          return {
            'codigo': '42',
            'titulo': 'Trabalho de transições',
            'descricao': 'Sessão focada em equilíbrio nas transições.',
            'duracaoEstimada': 45,
            'exercicios': [
              {
                'codigo': '12',
                'nome': 'Aquecimento ao passo',
                'duracao': 10,
                'descricao': 'Caminhada em pista.',
                'tipo': 'generico',
                'cavalo': null,
              },
              {
                'codigo': '18',
                'nome': 'Transições trote-galope',
                'duracao': 20,
                'descricao': 'Alternância entre andamentos.',
                'tipo': 'especifico',
                'cavalo': {
                  'codigo': '985141000123456',
                  'nome': 'Trovão',
                },
              },
            ],
            'orientacoes': ['Encerrar com 5 minutos de passo.'],
            'cargo': 'treinador',
          };
        },
      );

      final details = await repository.getTrainingDetails('  42  ');

      expect(capturedPayload, {'codigo': '42'});
      expect(details.code, '42');
      expect(details.title, 'Trabalho de transições');
      expect(details.description, 'Sessão focada em equilíbrio nas transições.');
      expect(details.estimatedDurationMinutes, 45);
      expect(details.role, TrainingViewerRole.trainer);
      expect(details.guidelines, ['Encerrar com 5 minutos de passo.']);
      expect(details.exercises, hasLength(2));

      expect(details.exercises[0].code, '12');
      expect(details.exercises[0].exerciseType, ExerciseType.generic);
      expect(details.exercises[0].horse, isNull);

      expect(details.exercises[1].code, '18');
      expect(details.exercises[1].exerciseType, ExerciseType.specific);
      expect(details.exercises[1].horse?.name, 'Trovão');
    },
  );

  test(
    'getTrainingDetails faz parse de cargo responsavel com tipo e cavalo nulos',
    () async {
      final repository = FirebaseTrainingDetailRepository(
        getTrainingDetails: (_) async => {
          'codigo': '42',
          'titulo': 'Trabalho de transições',
          'descricao': '',
          'duracaoEstimada': 45,
          'exercicios': [
            {
              'codigo': '12',
              'nome': 'Aquecimento ao passo',
              'duracao': 10,
              'descricao': 'Caminhada.',
              'tipo': null,
              'cavalo': null,
            },
          ],
          'orientacoes': [],
          'cargo': 'responsavel',
        },
      );

      final details = await repository.getTrainingDetails('42');

      expect(details.role, TrainingViewerRole.guardian);
      expect(details.displayDescription, 'Não informada');
      expect(details.exercises.first.exerciseType, isNull);
      expect(details.exercises.first.horse, isNull);
      expect(details.canManage(isTrainer: false), isFalse);
      expect(details.canManage(isTrainer: true), isFalse);
    },
  );

  test(
    'updateTraining resolve exercicioCodigos via getExercise quando vindo da galeria apenas com ObjectId',
    () async {
      Map<String, Object?>? capturedUpdatePayload;
      final fetchedExerciseIds = <String>[];

      final repository = FirebaseTrainingDetailRepository(
        getExercise: (payload) async {
          fetchedExerciseIds.add(payload['id'] as String);
          return {'id': payload['id'], 'codigo': 77, 'nome': 'Galope leve'};
        },
        updateTraining: (payload) async {
          capturedUpdatePayload = payload;
          return {
            'codigo': '42',
            'titulo': 'Trabalho de transições atualizado',
            'descricao': 'Nova descrição.',
            'duracaoEstimada': 50,
            'exercicios': [
              {
                'codigo': '12',
                'nome': 'Aquecimento ao passo',
                'duracao': 10,
                'descricao': 'Caminhada em pista.',
                'tipo': 'generico',
                'cavalo': null,
              },
              {
                'codigo': '77',
                'nome': 'Galope leve',
                'duracao': 20,
                'descricao': 'Galope controlado.',
                'tipo': 'generico',
                'cavalo': null,
              },
            ],
            'orientacoes': ['Encerrar com passo'],
            'cargo': 'treinador',
          };
        },
      );

      final updated = await repository.updateTraining(
        '42',
        const TrainingUpdate(
          title: '  Trabalho de transições atualizado  ',
          description: '  Nova descrição.  ',
          estimatedDurationMinutes: 50,
          guidelines: ['  Encerrar com passo  '],
          exercises: [
            TrainingExerciseItem(
              id: '12',
              code: 12,
              name: 'Aquecimento ao passo',
              estimatedDurationMinutes: 10,
              exerciseType: ExerciseType.generic,
            ),
            TrainingExerciseItem(
              id: '66e1a0c2f1b2c3d4e5f6c077',
              name: 'Galope leve',
              estimatedDurationMinutes: 20,
              exerciseType: ExerciseType.generic,
            ),
          ],
        ),
      );

      expect(fetchedExerciseIds, ['66e1a0c2f1b2c3d4e5f6c077']);
      expect(capturedUpdatePayload, {
        'codigo': '42',
        'titulo': 'Trabalho de transições atualizado',
        'descricao': 'Nova descrição.',
        'duracaoEstimada': 50,
        'orientacoes': ['Encerrar com passo'],
        'exercicioCodigos': ['12', '77'],
      });
      expect(updated.title, 'Trabalho de transições atualizado');
      expect(updated.exercises, hasLength(2));
    },
  );

  test(
    'updateTraining valida limites do contrato e mapeia erros FirebaseFunctionsException',
    () async {
      final repository = FirebaseTrainingDetailRepository(
        updateTraining: (_) async {
          throw FirebaseFunctionsException(
            code: 'permission-denied',
            message: 'Apenas treinadores podem editar treinamentos.',
          );
        },
      );

      expect(
        () => repository.updateTraining(
          '42',
          const TrainingUpdate(
            title: 'Ok',
            description: '',
            estimatedDurationMinutes: 30,
            guidelines: ['Orientação'],
            exercises: [
              TrainingExerciseItem(
                id: '12',
                code: 12,
                name: 'Aquecimento',
                estimatedDurationMinutes: 10,
                exerciseType: ExerciseType.generic,
              ),
            ],
          ),
        ),
        throwsA(isA<TrainingDetailFailure>()),
      );

      expect(
        () => repository.updateTraining(
          '42',
          const TrainingUpdate(
            title: 'Título válido',
            description: '',
            estimatedDurationMinutes: 15,
            guidelines: ['Orientação'],
            exercises: [
              TrainingExerciseItem(
                id: '12',
                code: 12,
                name: 'Aquecimento',
                estimatedDurationMinutes: 20,
                exerciseType: ExerciseType.generic,
              ),
            ],
          ),
        ),
        throwsA(isA<TrainingDetailFailure>()),
      );

      expect(
        () => repository.updateTraining(
          '42',
          const TrainingUpdate(
            title: 'Título válido',
            description: '',
            estimatedDurationMinutes: 30,
            guidelines: ['Orientação'],
            exercises: [
              TrainingExerciseItem(
                id: '12',
                code: 12,
                name: 'Aquecimento',
                estimatedDurationMinutes: 10,
                exerciseType: ExerciseType.generic,
              ),
            ],
          ),
        ),
        throwsA(
          isA<TrainingDetailFailure>().having(
            (e) => e.message,
            'message',
            'Apenas treinadores podem editar treinamentos.',
          ),
        ),
      );
    },
  );

  test(
    'getTrainingDetails com identificador não numérico e fallback sem exercícios retorna exercícios padrão',
    () async {
      const repository = FirebaseTrainingDetailRepository();

      final detail = await repository.getTrainingDetails(
        '66e1a0c2f1b2c3d4e5f6f101',
        fallbackTraining: const TrainingPlanGalleryItem(
          id: '66e1a0c2f1b2c3d4e5f6f101',
          code: 0,
          title: 'Fortalecimento',
          estimatedDurationMinutes: 0,
        ),
      );

      expect(detail.title, equals('Fortalecimento'));
      expect(detail.exercises, isNotEmpty);
      expect(detail.exercises.first.name, isNotEmpty);
    },
  );

  test(
    'getTrainingDetails com identificador não numérico e fallback com código sequencial consulta backend pelo código',
    () async {
      Map<String, Object?>? capturedPayload;

      final repository = FirebaseTrainingDetailRepository(
        getTrainingDetails: (payload) async {
          capturedPayload = payload;
          return {
            'codigo': '44',
            'titulo': 'Fortalecimento avançado',
            'descricao': 'Treino do banco de dados.',
            'duracaoEstimada': 50,
            'exercicios': [
              {
                'codigo': '21',
                'nome': 'Alongamento de pescoço',
                'duracao': 15,
                'descricao': 'Exercício do banco.',
                'tipo': 'generico',
                'cavalo': null,
              },
            ],
            'orientacoes': ['Passo 5 min'],
            'cargo': 'treinador',
          };
        },
      );

      final detail = await repository.getTrainingDetails(
        '66e1a0c2f1b2c3d4e5f6f101',
        fallbackTraining: const TrainingPlanGalleryItem(
          id: '66e1a0c2f1b2c3d4e5f6f101',
          code: 44,
          title: 'Fortalecimento',
          estimatedDurationMinutes: 45,
        ),
      );

      expect(capturedPayload?['codigo'], equals('44'));
      expect(detail.title, equals('Fortalecimento avançado'));
      expect(detail.exercises.length, equals(1));
    },
  );
}
