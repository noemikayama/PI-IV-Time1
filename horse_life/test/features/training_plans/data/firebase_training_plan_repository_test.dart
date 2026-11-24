// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Remoção de import redundante e adequação da formatação dos testes
// do parser de detalhes do plano de treinamento.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Teste para enriquecimento de trainingsByDay a partir de treinosDaSemana/todosOsTreinos.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Atualização das asserções de testes para planoId.
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição de testes unitários para getTrainingPlan, updateTrainingPlan
// e cancelTrainingPlan no FirebaseTrainingPlanRepository.
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
            message:
                'Este cavalo já tem um plano ativo. Ele termina em 31/12/2026.',
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

  test(
    'getTrainingPlan serializes id and parses planejamento snapshots',
    () async {
      Map<String, Object?>? capturedPayload;

      final repository = FirebaseTrainingPlanRepository(
        getTrainingPlan: (payload) async {
          capturedPayload = payload;
          return {
            'plano': {
              'id': '66e1a0c2f1b2c3d4e5f6e005',
              'codigo': 682,
              'titulo': 'Condicionamento para 1,00 m',
              'objetivo': 'Ganhar condicionamento físico',
              'status': 'ATIVO',
              'dataInicio': '2026-11-23',
              'dataFim': '2027-01-31',
              'cavalo': {'id': 'horse-1', 'nome': 'Calvino'},
              'treinador': {'id': 'trainer-1', 'nome': 'Carlos Mendes'},
              'planejamento': [
                {
                  'codigo': 1,
                  'ativo': true,
                  'diasSemana': ['SEGUNDA', 'QUARTA'],
                  'treinamento': {
                    'id': 'tr-1',
                    'codigo': 42,
                    'titulo': 'Trabalho de transições',
                    'descricao': 'Sessão focada em equilíbrio.',
                    'duracaoEstimadaMinutos': 45,
                    'exercicios': [
                      {'id': 'ex-1', 'nome': 'Aquecimento ao passo'},
                      {'id': 'ex-2', 'nome': 'Transições trote-galope'},
                    ],
                  },
                },
                {
                  'codigo': 2,
                  'ativo': false,
                  'diasSemana': ['SEXTA'],
                  'treinamento': {
                    'id': 'tr-old',
                    'codigo': 40,
                    'titulo': 'Item inativo',
                    'duracaoEstimadaMinutos': 20,
                    'exercicios': [],
                  },
                },
              ],
            },
          };
        },
      );

      final detail = await repository.getTrainingPlan(
        '  66e1a0c2f1b2c3d4e5f6e005  ',
      );

      expect(capturedPayload, {'planoId': '66e1a0c2f1b2c3d4e5f6e005'});
      expect(detail.id, '66e1a0c2f1b2c3d4e5f6e005');
      expect(detail.code, 682);
      expect(detail.title, 'Condicionamento para 1,00 m');
      expect(detail.objective, 'Ganhar condicionamento físico');
      expect(detail.status, TrainingPlanStatus.active);
      expect(detail.startDate, DateTime(2026, 11, 23));
      expect(detail.endDate, DateTime(2027, 1, 31));
      expect(
        detail.horse,
        const TrainerLinkedHorse(id: 'horse-1', name: 'Calvino'),
      );
      expect(detail.trainerId, 'trainer-1');
      expect(detail.trainerName, 'Carlos Mendes');
      expect(detail.trainingsByDay.keys, {
        TrainingPlanWeekday.monday,
        TrainingPlanWeekday.wednesday,
      });
      expect(
        detail.trainingsByDay[TrainingPlanWeekday.monday]?.description,
        'Sessão focada em equilíbrio.',
      );
      expect(detail.trainingsByDay[TrainingPlanWeekday.monday]?.exerciseNames, [
        'Aquecimento ao passo',
        'Transições trote-galope',
      ]);
    },
  );

  test(
    'getTrainingPlan enriches treinosPorDia with description and exercises from todosOsTreinos',
    () async {
      final repository = FirebaseTrainingPlanRepository(
        getTrainingPlan: (_) async => {
          'role': 'TREINADOR',
          'plano': {
            'id': '66e1a0c2f1b2c3d4e5f6e005',
            'codigo': 100,
            'titulo': 'Condicionamento',
            'objetivo': 'Melhorar físico',
            'dataInicio': '2026-11-23',
            'dataFim': '2027-01-31',
            'status': 'ATIVO',
          },
          'cavalo': {'id': '66e1a0c2f1b2c3d4e5f60050', 'nome': 'Trovão'},
          'permissoes': {'podeEditar': true, 'podeCancelar': true},
          'treinosPorDia': {
            'TERCA': {
              'id': '66e1a0c2f1b2c3d4e5f6d001',
              'codigo': 12,
              'titulo': 'Fortalecimento',
              'duracaoEstimadaMinutos': 380,
            },
          },
          'treinosDaSemana': {
            'dataInicio': '2026-11-23',
            'dataFim': '2026-11-29',
            'total': 1,
            'treinos': [
              {
                'data': '2026-11-24',
                'dataPorExtenso': 'Terça-feira, 24 de novembro de 2026',
                'diaSemana': 'Terça-feira',
                'treinamento': {
                  'codigo': '12',
                  'titulo': 'Fortalecimento',
                  'duracaoEstimadaMinutos': 380,
                  'descricao': 'Treino focado em força e explosão muscular.',
                  'exercicios': ['Cavaletes altos', 'Trote estendido'],
                },
              },
            ],
          },
          'todosOsTreinos': {'total': 1, 'treinos': []},
        },
      );

      final detail = await repository.getTrainingPlan(
        '66e1a0c2f1b2c3d4e5f6e005',
      );

      expect(
        detail.trainingsByDay.containsKey(TrainingPlanWeekday.tuesday),
        isTrue,
      );
      final tuesdayTraining =
          detail.trainingsByDay[TrainingPlanWeekday.tuesday]!;
      expect(tuesdayTraining.id, '66e1a0c2f1b2c3d4e5f6d001');
      expect(tuesdayTraining.code, 12);
      expect(tuesdayTraining.title, 'Fortalecimento');
      expect(tuesdayTraining.estimatedDurationMinutes, 380);
      expect(
        tuesdayTraining.description,
        'Treino focado em força e explosão muscular.',
      );
      expect(tuesdayTraining.exerciseNames, [
        'Cavaletes altos',
        'Trote estendido',
      ]);
    },
  );

  test(
    'updateTrainingPlan serializes full payload and maps permission-denied',
    () async {
      Map<String, Object?>? capturedPayload;
      final update = TrainingPlanUpdate(
        title: '  Plano Atualizado  ',
        objective: '  Novo objetivo  ',
        startDate: DateTime(2026, 11, 23),
        endDate: DateTime(2026, 12, 23),
        horse: horse,
        trainingsByDay: const {TrainingPlanWeekday.monday: sampleTraining},
      );

      final repository = FirebaseTrainingPlanRepository(
        updateTrainingPlan: (payload) async {
          capturedPayload = payload;
          return {
            'id': 'plan-1',
            'codigo': 682,
            'titulo': 'Plano Atualizado',
            'objetivo': 'Novo objetivo',
            'status': 'ATIVO',
            'dataInicio': '2026-11-23',
            'dataFim': '2026-12-23',
            'cavalo': {'id': horse.id, 'nome': horse.name},
            'treinador': {'id': 'trainer-1', 'nome': 'Carlos Mendes'},
            'planejamento': [],
          };
        },
      );

      final updated = await repository.updateTrainingPlan('plan-1', update);

      expect(capturedPayload, {
        'planoId': 'plan-1',
        'titulo': 'Plano Atualizado',
        'objetivo': 'Novo objetivo',
        'cavaloId': horse.id,
        'dataInicio': '2026-11-23',
        'dataFim': '2026-12-23',
        'treinosPorDia': {
          'SEGUNDA': sampleTraining.id,
          'TERCA': null,
          'QUARTA': null,
          'QUINTA': null,
          'SEXTA': null,
          'SABADO': null,
          'DOMINGO': null,
        },
      });
      expect(updated.title, 'Plano Atualizado');

      final failingRepository = FirebaseTrainingPlanRepository(
        updateTrainingPlan: (_) async {
          throw FirebaseFunctionsException(
            code: 'permission-denied',
            message: 'Apenas o treinador responsável pode editar este plano.',
          );
        },
      );

      expect(
        () => failingRepository.updateTrainingPlan('plan-1', update),
        throwsA(
          isA<TrainingPlanDetailFailure>().having(
            (e) => e.message,
            'message',
            'Apenas o treinador responsável pode editar este plano.',
          ),
        ),
      );
    },
  );

  test(
    'cancelTrainingPlan accepts partial confirmation and full plan payloads',
    () async {
      final partialRepo = FirebaseTrainingPlanRepository(
        cancelTrainingPlan: (payload) async {
          expect(payload, {'planoId': 'plan-1'});
          return {'cancelado': true};
        },
      );

      final partialResult = await partialRepo.cancelTrainingPlan('plan-1');
      expect(partialResult.id, 'plan-1');
      expect(partialResult.status, TrainingPlanStatus.canceled);

      final fullRepo = FirebaseTrainingPlanRepository(
        cancelTrainingPlan: (_) async => {
          'plano': {
            'id': 'plan-1',
            'codigo': 682,
            'titulo': 'Plano Cancelado',
            'objetivo': 'Objetivo',
            'status': 'CANCELADO',
            'dataInicio': '2026-11-23',
            'dataFim': '2026-12-23',
            'cavalo': {'id': horse.id, 'nome': horse.name},
            'treinador': {'id': 'trainer-1', 'nome': 'Carlos Mendes'},
            'planejamento': [],
          },
        },
      );

      final fullResult = await fullRepo.cancelTrainingPlan('plan-1');
      expect(fullResult.title, 'Plano Cancelado');
      expect(fullResult.status, TrainingPlanStatus.canceled);
    },
  );
}
