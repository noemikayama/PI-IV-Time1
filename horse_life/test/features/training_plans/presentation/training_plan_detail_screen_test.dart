// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Teste do fechamento da rota com resultado true ao cancelar plano.
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes de widget das telas de visualização e edição
// de planos de treinamento, cobrindo permissões, botões por status, carrossel
// semanal, empty state de avaliação, cancelamento com modal e edição integrada.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/data/repositories/trainer_linked_horse_repository.dart';
import 'package:horse_life/features/training_plans/data/mocks/mock_training_plan_gallery.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_detail_data.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_gallery_item.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_weekday.dart';
import 'package:horse_life/features/training_plans/data/repositories/training_plan_repository.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_detail_screen.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_edit_screen.dart';

class _SpyPlanDetailRepository extends LocalTrainingPlanRepository {
  _SpyPlanDetailRepository({
    TrainingPlanDetailData? currentPlan,
    this.failDetailFirstCall = false,
  }) : _currentPlan = currentPlan ?? _samplePlan();

  TrainingPlanDetailData _currentPlan;
  bool failDetailFirstCall;
  int getCalls = 0;
  int updateCalls = 0;
  int cancelCalls = 0;
  TrainingPlanUpdate? lastUpdate;

  @override
  Future<TrainingPlanDetailData> getTrainingPlan(String planId) async {
    getCalls++;
    if (failDetailFirstCall && getCalls == 1) {
      throw const TrainingPlanDetailFailure('Falha simulada ao carregar plano.');
    }
    return _currentPlan;
  }

  @override
  Future<TrainingPlanDetailData> updateTrainingPlan(
    String planId,
    TrainingPlanUpdate update,
  ) async {
    updateCalls++;
    lastUpdate = update;
    _currentPlan = update.applyTo(_currentPlan);
    return _currentPlan;
  }

  @override
  Future<TrainingPlanDetailData> cancelTrainingPlan(String planId) async {
    cancelCalls++;
    _currentPlan = _currentPlan.copyWith(status: TrainingPlanStatus.canceled);
    return _currentPlan;
  }
}

TrainingPlanDetailData _samplePlan({
  TrainingPlanStatus status = TrainingPlanStatus.active,
}) {
  return TrainingPlanDetailData(
    id: 'plan-1',
    code: 682,
    title: 'Condicionamento para 1,00 m',
    objective: 'Ganhar condicionamento para percursos de 1,00 m',
    startDate: DateTime(2026, 11, 23),
    endDate: DateTime(2027, 1, 31),
    horse: const TrainerLinkedHorse(id: 'horse-1', name: 'Calvino'),
    trainerId: 'trainer-1',
    trainerName: 'Carlos Mendes',
    status: status,
    trainingsByDay: {
      TrainingPlanWeekday.monday: MockTrainingPlanGallery.trainings[1],
      TrainingPlanWeekday.wednesday: MockTrainingPlanGallery.trainings[0],
      TrainingPlanWeekday.friday: MockTrainingPlanGallery.trainings[2],
    },
  );
}

void main() {
  Widget buildApp(Widget screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets(
    'mostra visualização completa ao treinador proprietário com plano ativo, carrossel, links e empty state de avaliação',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var openedAgenda = false;
      TrainingPlanGalleryItem? viewedTraining;

      await tester.pumpWidget(
        buildApp(
          TrainingPlanDetailScreen(
            planId: 'plan-1',
            currentUserId: 'trainer-1',
            isTrainer: true,
            repository: _SpyPlanDetailRepository(),
            onOpenTrainingAgenda: () => openedAgenda = true,
            onViewTrainingDetails: (training) => viewedTraining = training,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Condicionamento para 1,00 m'), findsWidgets);
      expect(find.byKey(const Key('edit-training-plan-button')), findsOneWidget);
      expect(
        find.byKey(const Key('cancel-training-plan-button')),
        findsOneWidget,
      );

      expect(find.textContaining('Início: 23/11/2026'), findsOneWidget);
      expect(find.textContaining('Fim: 31/01/2027'), findsOneWidget);
      expect(find.textContaining('Cavalo vinculado: Calvino'), findsOneWidget);
      expect(find.textContaining('Status: Ativo'), findsOneWidget);
      expect(find.textContaining('Treinador:'), findsNothing);

      expect(find.text('Segunda-feira (1/3)'), findsOneWidget);
      expect(find.text('Trabalho de transições'), findsOneWidget);
      expect(
        find.textContaining('Sessão focada em equilíbrio nas transições'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('training-plan-view-details-button')));
      await tester.pumpAndSettle();
      expect(viewedTraining?.title, 'Trabalho de transições');

      await tester.tap(find.byKey(const Key('training-plan-page-indicator-1')));
      await tester.pumpAndSettle();
      expect(find.text('Quarta-feira (2/3)'), findsOneWidget);
      expect(find.text('Aquecimento e flexibilidade'), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('training-plan-weekly-swipe-area')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sexta-feira (3/3)'), findsOneWidget);
      expect(find.text('Cavaletes e ritmo'), findsOneWidget);

      await tester.tap(find.byKey(const Key('training-plan-view-all-button')));
      await tester.pumpAndSettle();
      expect(openedAgenda, isTrue);

      expect(
        find.byKey(const Key('training-plan-evaluation-empty-state')),
        findsOneWidget,
      );
      expect(find.text('Nenhuma avaliação vinculada'), findsOneWidget);

      // Valida colapso e expansão de seção reutilizável.
      await tester.tap(find.text('Avaliação vinculada'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('training-plan-evaluation-empty-state')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'oculta cancelar plano quando o plano não está ativo para o treinador proprietário',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildApp(
          TrainingPlanDetailScreen(
            planId: 'plan-1',
            currentUserId: 'trainer-1',
            isTrainer: true,
            repository: _SpyPlanDetailRepository(
              currentPlan: _samplePlan(status: TrainingPlanStatus.completed),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit-training-plan-button')), findsOneWidget);
      expect(
        find.byKey(const Key('cancel-training-plan-button')),
        findsNothing,
      );
      expect(find.textContaining('Status: Concluído'), findsOneWidget);
    },
  );

  testWidgets(
    'oculta editar e cancelar e exibe nome do treinador para responsável e outro treinador',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildApp(
          TrainingPlanDetailScreen(
            planId: 'plan-1',
            currentUserId: 'guardian-1',
            isTrainer: false,
            repository: _SpyPlanDetailRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit-training-plan-button')), findsNothing);
      expect(
        find.byKey(const Key('cancel-training-plan-button')),
        findsNothing,
      );
      expect(find.textContaining('Treinador: Carlos Mendes'), findsOneWidget);

      await tester.pumpWidget(
        buildApp(
          TrainingPlanDetailScreen(
            planId: 'plan-1',
            currentUserId: 'trainer-other',
            isTrainer: true,
            repository: _SpyPlanDetailRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit-training-plan-button')), findsNothing);
      expect(
        find.byKey(const Key('cancel-training-plan-button')),
        findsNothing,
      );
      expect(find.textContaining('Treinador: Carlos Mendes'), findsOneWidget);
    },
  );

  testWidgets(
    'confirma cancelamento do plano antes de chamar cancelTrainingPlan e atualiza status',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _SpyPlanDetailRepository();

      await tester.pumpWidget(
        buildApp(
          TrainingPlanDetailScreen(
            planId: 'plan-1',
            currentUserId: 'trainer-1',
            isTrainer: true,
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('cancel-training-plan-button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Tem certeza que deseja cancelar esse plano?'),
        findsOneWidget,
      );
      expect(repository.cancelCalls, 0);

      await tester.tap(
        find.byKey(const Key('destructive-dialog-cancel-button')),
      );
      await tester.pumpAndSettle();
      expect(repository.cancelCalls, 0);
      expect(find.textContaining('Status: Ativo'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cancel-training-plan-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('destructive-dialog-confirm-button')),
      );
      await tester.pumpAndSettle();

      expect(repository.cancelCalls, 1);
      expect(find.textContaining('Status: Cancelado'), findsOneWidget);
      expect(
        find.byKey(const Key('cancel-training-plan-button')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'abre tela de edição sem campo de avaliação e atualiza plano após salvar alterações',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _SpyPlanDetailRepository();

      await tester.pumpWidget(
        buildApp(
          TrainingPlanDetailScreen(
            planId: 'plan-1',
            currentUserId: 'trainer-1',
            isTrainer: true,
            repository: repository,
            horseRepository: const LocalTrainerLinkedHorseRepository(
              horses: [
                TrainerLinkedHorse(id: 'horse-1', name: 'Calvino'),
                TrainerLinkedHorse(id: 'horse-2', name: 'Trovão'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-training-plan-button')));
      await tester.pumpAndSettle();

      expect(find.byType(TrainingPlanEditScreen), findsOneWidget);
      expect(find.text('Editar plano'), findsOneWidget);
      expect(find.text('Avaliação inicial selecionada'), findsNothing);

      await tester.tap(find.byTooltip('Editar Título'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('training-plan-edit-title-field')),
        'Condicionamento Intensivo',
      );
      await tester.pump();

      final removeFridayButton = find.byKey(
        const Key('remove-weekday-training-friday'),
      );
      await tester.ensureVisible(removeFridayButton);
      await tester.tap(removeFridayButton);
      await tester.pumpAndSettle();

      final saveButton = find.byKey(
        const Key('save-training-plan-edit-button'),
      );
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.byType(TrainingPlanEditScreen), findsNothing);
      expect(repository.updateCalls, 1);
      expect(repository.lastUpdate?.title, 'Condicionamento Intensivo');
      expect(find.text('Condicionamento Intensivo'), findsWidgets);
      expect(find.text('Segunda-feira (1/2)'), findsOneWidget);
    },
  );

  testWidgets(
    'exibe erro de carregamento com tentar novamente e propaga destino da barra inferior',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _SpyPlanDetailRepository(failDetailFirstCall: true);
      HomeNavigationDestination? selectedDestination;

      await tester.pumpWidget(
        buildApp(
          TrainingPlanDetailScreen(
            planId: 'plan-1',
            currentUserId: 'trainer-1',
            isTrainer: true,
            repository: repository,
            onNavigationSelected: (destination) =>
                selectedDestination = destination,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Falha simulada ao carregar plano.'), findsOneWidget);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(find.text('Condicionamento para 1,00 m'), findsWidgets);

      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(selectedDestination, HomeNavigationDestination.dashboard);
    },
  );

  testWidgets(
    'fecha rota com pop(true) ao cancelar plano quando estiver empilhada no Navigator',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _SpyPlanDetailRepository();
      dynamic poppedResult;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                key: const Key('open-detail-button'),
                onPressed: () async {
                  poppedResult = await Navigator.of(context).push<dynamic>(
                    MaterialPageRoute<dynamic>(
                      builder: (_) => TrainingPlanDetailScreen(
                        planId: 'plan-1',
                        currentUserId: 'trainer-1',
                        isTrainer: true,
                        repository: repository,
                      ),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('open-detail-button')));
      await tester.pumpAndSettle();

      expect(find.text('Condicionamento para 1,00 m'), findsWidgets);

      await tester.tap(find.byKey(const Key('cancel-training-plan-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('destructive-dialog-confirm-button')),
      );
      await tester.pumpAndSettle();

      expect(repository.cancelCalls, 1);
      expect(poppedResult, true);
      expect(find.byKey(const Key('open-detail-button')), findsOneWidget);
    },
  );
}
