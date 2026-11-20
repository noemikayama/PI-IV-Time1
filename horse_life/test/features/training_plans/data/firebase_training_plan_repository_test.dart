// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes unitários do FirebaseTrainingPlanRepository,
// cobrindo serialização de listTrainingGallery e createTrainingPlan, validação
// de regras do contrato e mapeamento de FirebaseFunctionsException.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/training_plans/application/states/training_plan_registration_draft.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_gallery_item.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_weekday.dart';
import 'package:horse_life/features/training_plans/data/repositories/firebase_training_plan_repository.dart';
import 'package:horse_life/features/training_plans/data/repositories/training_plan_repository.dart';

void main() {
  const horse = TrainerLinkedHorse(
    id: '66e1a0c2f1b2c3d4e5f60050',
    name: 'Trovão',
  );

  const sampleTraining = TrainingPlanGalleryItem(
    id: '66e1a0c2f1b2c3d4e5f6d001',
    code: 42,
    title: 'Trabalho de transições',
    estimatedDurationMinutes: 45,
    exerciseNames: ['Aquecimento ao passo', 'Transições trote-galope'],
  );

  test(
    'fetchTrainingGallery serializes cavaloId and optional busca and parses trainings',
    () async {
      Map<String, Object?>? capturedPayload;

      final repository = FirebaseTrainingPlanRepository(
        listTrainingGallery: (payload) async {
          capturedPayload = payload;
          return {
            'treinamentos': [
              {
                'id': '66e1a0c2f1b2c3d4e5f6d001',
                'codigo': 42,
                'titulo': 'Trabalho de transições',
                'duracaoEstimadaMinutos': 45,
                'exercicios': [
                  'Aquecimento ao passo',
                  'Transições trote-galope',
                ],
              },
            ],
          };
        },
      );

      final items = await repository.fetchTrainingGallery(
        horseId: '66e1a0c2f1b2c3d4e5f60050',
        searchQuery: '  trans  ',
      );

      expect(capturedPayload, {
        'cavaloId': '66e1a0c2f1b2c3d4e5f60050',
        'busca': 'trans',
      });
      expect(items, hasLength(1));
      expect(items.first.id, '66e1a0c2f1b2c3d4e5f6d001');
      expect(items.first.code, 42);
      expect(items.first.title, 'Trabalho de transições');
      expect(items.first.estimatedDurationMinutes, 45);
      expect(items.first.exerciseNames, [
        'Aquecimento ao passo',
        'Transições trote-galope',
      ]);
    },
  );

  test(
    'createTrainingPlan serializes full payload and parses response result',
    () async {
      Map<String, Object?>? capturedPayload;
      final today = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
      final endDate = DateTime(today.year, today.month, today.day + 30);

      final repository = FirebaseTrainingPlanRepository(
        createTrainingPlan: (payload) async {
          capturedPayload = payload;
          return {
            'plano': {
              'id': '66e1a0c2f1b2c3d4e5f6e005',
              'codigo': 682,
              'status': 'ATIVO',
              'dataInicio': TrainingPlanRegistrationDraft.formatYmd(today),
              'dataFim': TrainingPlanRegistrationDraft.formatYmd(endDate),
              'planejamento': [],
            },
            'registrosGerados': 15,
          };
        },
      );

      final draft = TrainingPlanRegistrationDraft(
        title: '  Condicionamento para percursos de 1,00 m  ',
        objective: '  Ganhar condicionamento para percursos de 1,00 m  ',
        horse: horse,
        startDate: today,
        endDate: endDate,
        trainingsByDay: const {
          TrainingPlanWeekday.monday: sampleTraining,
          TrainingPlanWeekday.wednesday: sampleTraining,
        },
      );

      final result = await repository.createTrainingPlan(draft: draft);

      expect(capturedPayload, {
        'titulo': 'Condicionamento para percursos de 1,00 m',
        'objetivo': 'Ganhar condicionamento para percursos de 1,00 m',
        'cavaloId': '66e1a0c2f1b2c3d4e5f60050',
        'avaliacaoId': null,
        'dataInicio': TrainingPlanRegistrationDraft.formatYmd(today),
        'dataFim': TrainingPlanRegistrationDraft.formatYmd(endDate),
        'treinosPorDia': {
          'SEGUNDA': '66e1a0c2f1b2c3d4e5f6d001',
          'TERCA': null,
          'QUARTA': '66e1a0c2f1b2c3d4e5f6d001',
          'QUINTA': null,
          'SEXTA': null,
          'SABADO': null,
          'DOMINGO': null,
        },
      });
      expect(result.id, '66e1a0c2f1b2c3d4e5f6e005');
      expect(result.code, 682);
      expect(result.status, 'ATIVO');
      expect(result.generatedRecordsCount, 15);
    },
  );

  test(
    'createTrainingPlan validates bounds and maps failed-precondition errors',
    () async {
      final today = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
      final endDate = DateTime(today.year, today.month, today.day + 14);

      final repository = FirebaseTrainingPlanRepository(
        createTrainingPlan: (_) async {
          throw FirebaseFunctionsException(
            code: 'failed-precondition',
            message: 'Este cavalo já tem um plano ativo. Ele termina em 31/12/2026.',
          );
        },
      );

      expect(
        () => repository.createTrainingPlan(
          draft: TrainingPlanRegistrationDraft(
            title: 'Plano válido',
            objective: 'Objetivo válido',
            horse: horse,
            startDate: today,
            endDate: endDate,
            trainingsByDay: const {},
          ),
        ),
        throwsA(isA<TrainingPlanRegistrationFailure>()),
      );

      expect(
        () => repository.createTrainingPlan(
          draft: TrainingPlanRegistrationDraft(
            title: 'Plano válido',
            objective: 'Objetivo válido',
            horse: horse,
            startDate: today,
            endDate: TrainingPlanRegistrationDraft.addMonths(today, 12),
            trainingsByDay: const {TrainingPlanWeekday.monday: sampleTraining},
          ),
        ),
        throwsA(isA<TrainingPlanRegistrationFailure>()),
      );

      expect(
        () => repository.createTrainingPlan(
          draft: TrainingPlanRegistrationDraft(
            title: 'Plano válido',
            objective: 'Objetivo válido',
            horse: horse,
            startDate: today,
            endDate: endDate,
            trainingsByDay: const {TrainingPlanWeekday.monday: sampleTraining},
          ),
        ),
        throwsA(
          isA<TrainingPlanRegistrationFailure>().having(
            (e) => e.message,
            'message',
            'Este cavalo já tem um plano ativo. Ele termina em 31/12/2026.',
          ),
        ),
      );
    },
  );
}
