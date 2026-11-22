// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa 6 de 7 (Seleção de treinamentos por dia
// da semana) e do bottom sheet da galeria de treinamentos, cobrindo seleção,
// busca, remoção, estado vazio, retorno da criação e navegação para revisão.
// -----------------------------------------------------------------------------

import '../../../support/features/training_plans/data/repositories/local_training_plan_repository.dart';
import '../../../support/features/trainings/data/repositories/local_training_registration_repository.dart';
import '../../../support/features/trainings/data/repositories/local_training_exercise_gallery_repository.dart';
import '../../../support/features/exercises/data/repositories/local_trainer_linked_horse_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/training_plans/application/controllers/training_plan_registration_controller.dart';
import 'package:horse_life/features/training_plans/application/states/training_plan_registration_draft.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_confirmation_screen.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_trainings_screen.dart';
import 'package:horse_life/features/trainings/application/controllers/training_registration_controller.dart';
import 'package:horse_life/features/trainings/application/states/training_registration_draft.dart';
import 'package:horse_life/features/trainings/data/models/training_exercise_item.dart';
import 'package:horse_life/features/trainings/data/repositories/training_registration_repository.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_title_screen.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  const calvino = TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino');

  TrainingPlanRegistrationDraft buildSampleDraft() {
    final startDate = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
    final endDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day + 14,
    );
    return TrainingPlanRegistrationDraft(
      title: 'Condicionamento 1,00 m',
      objective: 'Ganhar condicionamento para percursos de 1,00 m.',
      horse: calvino,
      startDate: startDate,
      endDate: endDate,
    );
  }

  testWidgets(
    'renders 7 weekdays, requires at least one training, selects from gallery, removes and advances to review',
    (tester) async {
      await tester.pumpWidget(
        buildApp(TrainingPlanTrainingsScreen(controller: TrainingPlanRegistrationController(horseRepository: const LocalTrainerLinkedHorseRepository(), planRepository: const LocalTrainingPlanRepository()), draft: buildSampleDraft())),
      );

      expect(find.text('Seleção de\ntreinamentos'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 6 de 7'), findsOneWidget);
      expect(find.text('Segunda-feira'), findsOneWidget);
      expect(find.text('Domingo'), findsOneWidget);

      final continueButton = find.byKey(
        const Key('continue-training-plan-trainings'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Selecione um treinamento para pelo menos um dia da semana.'),
        findsOneWidget,
      );
      expect(find.byType(TrainingPlanConfirmationScreen), findsNothing);

      // Abre a galeria para Segunda-feira
      final addMondayGallery = find.byKey(
        const Key('add-gallery-training-monday'),
      );
      await tester.ensureVisible(addMondayGallery);
      await tester.tap(addMondayGallery);
      await tester.pumpAndSettle();

      expect(find.text('Galeria de treinamentos'), findsOneWidget);
      expect(find.text('Aquecimento e flexibilidade'), findsOneWidget);
      expect(find.text('Trabalho de transições'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('training-gallery-search-input')),
        'transicoes',
      );
      await tester.pumpAndSettle();

      expect(find.text('Trabalho de transições'), findsOneWidget);
      expect(find.text('Aquecimento e flexibilidade'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('gallery-training-card-tr-2')));
      await tester.pumpAndSettle();

      // Fecha o bottom sheet
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Trabalho de transições'), findsOneWidget);
      expect(find.text('45 min'), findsOneWidget);

      // Remove o treinamento selecionado na segunda-feira
      final removeMonday = find.byKey(
        const ValueKey('remove-weekday-training-monday'),
      );
      await tester.ensureVisible(removeMonday);
      await tester.tap(removeMonday);
      await tester.pumpAndSettle();

      expect(find.text('Trabalho de transições'), findsNothing);

      // Seleciona novamente na galeria para avançar até a revisão
      await tester.ensureVisible(addMondayGallery);
      await tester.tap(addMondayGallery);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('gallery-training-card-tr-2')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(TrainingPlanConfirmationScreen), findsOneWidget);
      expect(find.text('Revise os dados'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 7 de 7'), findsOneWidget);
    },
  );

  testWidgets(
    'shows empty gallery state when no trainings exist and navigates to create training',
    (tester) async {
      final controller = TrainingPlanRegistrationController(horseRepository: const LocalTrainerLinkedHorseRepository(),
        planRepository: const LocalTrainingPlanRepository(trainings: []),
      );

      await tester.pumpWidget(
        buildApp(
          TrainingPlanTrainingsScreen(
            draft: buildSampleDraft(),
            controller: controller,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('add-gallery-training-monday')));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum treinamento criado'), findsOneWidget);
      expect(
        find.byKey(const Key('empty-gallery-create-training-button')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('empty-gallery-create-training-button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TrainingTitleScreen), findsOneWidget);
    },
  );

  testWidgets(
    'returns from training creation and assigns created training to weekday',
    (tester) async {
      final planController = TrainingPlanRegistrationController(horseRepository: const LocalTrainerLinkedHorseRepository(),
        planRepository: const LocalTrainingPlanRepository(trainings: []),
      );
      final trainingController = TrainingRegistrationController(galleryRepository: const LocalTrainingExerciseGalleryRepository(), horseRepository: const LocalTrainerLinkedHorseRepository(), registrationRepository: const LocalTrainingRegistrationRepository());

      await tester.pumpWidget(
        buildApp(
          TrainingPlanTrainingsScreen(
            draft: buildSampleDraft(),
            controller: planController,
            trainingRegistrationController: trainingController,
          ),
        ),
      );

      final createTuesday = find.byKey(const Key('create-training-tuesday'));
      await tester.ensureVisible(createTuesday);
      await tester.tap(createTuesday);
      await tester.pumpAndSettle();

      expect(find.byType(TrainingTitleScreen), findsOneWidget);

      // Simula conclusão do treinamento criado na sessão e retorno da rota
      final navContext = tester.element(find.byType(TrainingTitleScreen));
      final routeController = navContext
          .findAncestorWidgetOfExactType<TrainingTitleScreen>()!
          .controller!;
      routeController.onTrainingCreated?.call(
        const TrainingRegistrationDraft(
          title: 'Treino Novo Sessão',
          description: 'Descrição',
          estimatedDurationMinutes: 35,
          selectedExercises: [
            TrainingExerciseItem(
              id: 'ex-1',
              name: 'Aquecimento ao passo',
              estimatedDurationMinutes: 10,
              exerciseType: ExerciseType.generic,
            ),
          ],
          guidelines: ['Manter ritmo constante'],
        ),
        const TrainingRegistrationResult(
          id: 'tr-new-1',
          code: 99,
          title: 'Treino Novo Sessão',
        ),
      );
      Navigator.of(navContext).pop();
      await tester.pumpAndSettle();

      expect(find.byType(TrainingPlanTrainingsScreen), findsOneWidget);
      expect(find.text('Treino Novo Sessão'), findsOneWidget);
      expect(find.text('35 min'), findsOneWidget);
    },
  );
}
