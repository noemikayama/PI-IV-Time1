// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação e comentários dos cenários de teste
// de widget para visualização e edição de treinamentos.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes de widget das telas de visualização e edição
// de treinamentos (TrainingDetailScreen e TrainingEditScreen), cobrindo
// seções recolhíveis, carrossel de exercícios, orientações, permissões por
// treinador proprietário, modais de adição e salvamento integrado.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/data/repositories/trainer_linked_horse_repository.dart';
import 'package:horse_life/features/trainings/application/controllers/training_registration_controller.dart';
import 'package:horse_life/features/trainings/data/models/training_detail_data.dart';
import 'package:horse_life/features/trainings/data/repositories/training_detail_repository.dart';
import 'package:horse_life/features/trainings/data/repositories/training_exercise_gallery_repository.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_detail_screen.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_edit_screen.dart';

class _SpyTrainingDetailRepository extends LocalTrainingDetailRepository {
  _SpyTrainingDetailRepository({
    super.initialTraining
  });

  int getCalls = 0;
  int updateCalls = 0;
  TrainingUpdate? lastUpdate;

  @override
  Future<TrainingDetailData> getTrainingDetails(
    String trainingCode, {
    fallbackTraining,
  }) async {
    getCalls++;
    return super.getTrainingDetails(
      trainingCode,
      fallbackTraining: fallbackTraining,
    );
  }

  @override
  Future<TrainingDetailData> updateTraining(
    String trainingCode,
    TrainingUpdate update,
  ) async {
    updateCalls++;
    lastUpdate = update;
    return super.updateTraining(trainingCode, update);
  }
}

TrainingDetailData _sampleTraining({
  TrainingViewerRole role = TrainingViewerRole.trainer,
  String trainerId = 'trainer-1',
}) {
  return TrainingDetailData(
    code: '42',
    title: 'Trabalho de transições',
    description: 'Sessão focada em equilíbrio nas transições de andamento.',
    estimatedDurationMinutes: 45,
    role: role,
    trainerId: trainerId,
    guidelines: const [
      'Encerrar com 5 minutos de passo.',
      'Descansar 3 minutos entre cada exercício.',
    ],
    exercises: const [
      TrainingDetailExercise(
        code: '101',
        id: 'ex-generic-1',
        name: 'Aquecimento ao passo',
        durationMinutes: 10,
        description: 'Caminhada em pista para aquecimento muscular.',
        exerciseType: ExerciseType.generic,
      ),
      TrainingDetailExercise(
        code: '104',
        id: 'ex-specific-calvino-1',
        name: 'Transições trote-galope',
        durationMinutes: 20,
        description: 'Alternância controlada entre trote e galope.',
        exerciseType: ExerciseType.specific,
        horse: TrainerLinkedHorse(id: 'horse-1', name: 'Calvino'),
      ),
    ],
  );
}

void main() {
  Widget buildApp(Widget screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets(
    'exibe visualização completa ao treinador proprietário com botão Editar treino, carrossel de exercícios e orientações',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      TrainingDetailExercise? viewedExercise;
      final repository = _SpyTrainingDetailRepository(
        initialTraining: _sampleTraining(),
      );

      await tester.pumpWidget(
        buildApp(
          TrainingDetailScreen(
            trainingCode: '42',
            currentUserId: 'trainer-1',
            isTrainer: true,
            repository: repository,
            onViewExerciseDetails: (exercise) => viewedExercise = exercise,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit-training-button')), findsOneWidget);
      expect(find.text('Trabalho de transições'), findsWidgets);
      expect(find.textContaining('Duração estimada: 45 min'), findsOneWidget);
      expect(find.text('Aquecimento ao passo'), findsOneWidget);
      expect(find.text('Encerrar com 5 minutos de passo.'), findsOneWidget);
      expect(
        find.text('Descansar 3 minutos entre cada exercício.'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('training-exercise-view-details-button')),
      );
      await tester.pumpAndSettle();
      expect(viewedExercise?.name, 'Aquecimento ao passo');

      await tester.tap(
        find.byKey(const Key('training-exercise-page-indicator-1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Transições trote-galope'), findsOneWidget);

      await tester.tap(find.text('Dados do treinamento'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Duração estimada: 45 min'), findsNothing);
    },
  );

  testWidgets(
    'oculta botão Editar treino para responsável e para treinador não proprietário',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildApp(
          TrainingDetailScreen(
            trainingCode: '42',
            currentUserId: 'guardian-1',
            isTrainer: false,
            repository: _SpyTrainingDetailRepository(
              initialTraining: _sampleTraining(
                role: TrainingViewerRole.guardian,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-training-button')), findsNothing);

      await tester.pumpWidget(
        buildApp(
          TrainingDetailScreen(
            trainingCode: '42',
            currentUserId: 'trainer-other',
            isTrainer: true,
            repository: _SpyTrainingDetailRepository(
              initialTraining: _sampleTraining(trainerId: 'trainer-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('edit-training-button')), findsNothing);
    },
  );

  testWidgets(
    'abre tela de edição, usa modais do cadastro para orientações e exercícios e salva alterações',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repository = _SpyTrainingDetailRepository(
        initialTraining: _sampleTraining(),
      );
      final trainingController = TrainingRegistrationController(
        galleryRepository: const LocalTrainingExerciseGalleryRepository(),
        horseRepository: const LocalTrainerLinkedHorseRepository(),
      );

      await tester.pumpWidget(
        buildApp(
          TrainingDetailScreen(
            trainingCode: '42',
            currentUserId: 'trainer-1',
            isTrainer: true,
            repository: repository,
            trainingRegistrationController: trainingController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-training-button')));
      await tester.pumpAndSettle();
      expect(find.byType(TrainingEditScreen), findsOneWidget);

      // Edita o título inline.
      await tester.tap(find.byTooltip('Editar Título'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('training-edit-title-field')),
        'Treino de ritmo ajustado',
      );
      await tester.pump();

      // Abre o modal de adicionar orientação do cadastro.
      await tester.tap(
        find.byKey(const Key('training-edit-add-guideline-button')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('training-guideline-input')),
        'Evitar aceleração excessiva nas curvas.',
      );
      await tester.tap(find.byKey(const Key('save-training-guideline')));
      await tester.pumpAndSettle();
      expect(
        find.text('Evitar aceleração excessiva nas curvas.'),
        findsOneWidget,
      );

      // Abre a galeria de exercícios do cadastro e marca mais um exercício genérico.
      await tester.ensureVisible(
        find.byKey(const Key('training-edit-open-exercise-gallery-button')),
      );
      await tester.tap(
        find.byKey(const Key('training-edit-open-exercise-gallery-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Galeria de exercícios'), findsOneWidget);
      await tester.tap(find.text('Alongamento de pescoço'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Galeria de exercícios'))).pop();
      await tester.pumpAndSettle();
      expect(find.text('Alongamento de pescoço'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('save-training-edit-button')),
      );
      await tester.tap(find.byKey(const Key('save-training-edit-button')));
      await tester.pumpAndSettle();

      expect(repository.updateCalls, 1);
      expect(repository.lastUpdate?.title, 'Treino de ritmo ajustado');
      expect(
        repository.lastUpdate?.guidelines,
        contains('Evitar aceleração excessiva nas curvas.'),
      );
      expect(
        repository.lastUpdate?.exercises.map((e) => e.name),
        contains('Alongamento de pescoço'),
      );
      expect(find.byType(TrainingDetailScreen), findsOneWidget);
      expect(find.text('Treino de ritmo ajustado'), findsWidgets);
    },
  );
}
