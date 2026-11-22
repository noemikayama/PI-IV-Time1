// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa 6 de 6 (Revisão dos dados do
// treinamento), cobrindo edição inline de campos, remoção de orientações e
// exercícios, bloqueio ao remover todos os exercícios e submissão com retorno.
// -----------------------------------------------------------------------------

import '../../../support/features/trainings/data/repositories/local_training_registration_repository.dart';
import '../../../support/features/trainings/data/repositories/local_training_exercise_gallery_repository.dart';
import '../../../support/features/exercises/data/repositories/local_trainer_linked_horse_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/trainings/application/controllers/training_registration_controller.dart';
import 'package:horse_life/features/trainings/application/states/training_registration_draft.dart';
import 'package:horse_life/features/trainings/data/models/training_exercise_item.dart';
import 'package:horse_life/features/trainings/data/repositories/training_registration_repository.dart';
import 'package:horse_life/features/trainings/presentation/routes/training_registration_flow_route.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_confirmation_screen.dart';

class _SpyTrainingRegistrationRepository
    extends LocalTrainingRegistrationRepository {
  TrainingRegistrationDraft? submittedDraft;

  @override
  Future<TrainingRegistrationResult> registerTraining({
    required TrainingRegistrationDraft draft,
  }) async {
    submittedDraft = draft;
    return super.registerTraining(draft: draft);
  }
}

void main() {
  Widget buildApp(Widget screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  const calvino = TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino');

  const sampleDraft = TrainingRegistrationDraft(
    title: 'Trabalho de transições',
    description: 'Sessão focada em equilíbrio nas transições de andamento.',
    estimatedDurationMinutes: 45,
    guidelines: [
      'Encerrar com 5 minutos de passo',
      'Descansar 3 minutos entre cada exercício',
    ],
    selectedExercises: [
      TrainingExerciseItem(
        id: 'ex-specific-1',
        name: 'Transições trote-galope',
        estimatedDurationMinutes: 20,
        exerciseType: ExerciseType.specific,
        horse: calvino,
      ),
      TrainingExerciseItem(
        id: 'ex-generic-1',
        name: 'Aquecimento ao passo',
        estimatedDurationMinutes: 10,
        exerciseType: ExerciseType.generic,
      ),
    ],
  );

  testWidgets(
    'renders fields, allows inline edits and item removal before submitting',
    (tester) async {
      TrainingRegistrationDraft? submittedDraft;

      await tester.pumpWidget(
        buildApp(
          TrainingConfirmationScreen(controller: TrainingRegistrationController(galleryRepository: const LocalTrainingExerciseGalleryRepository(), horseRepository: const LocalTrainerLinkedHorseRepository(), registrationRepository: const LocalTrainingRegistrationRepository()),
            draft: sampleDraft,
            onSubmitted: (draft) => submittedDraft = draft,
          ),
        ),
      );

      expect(find.text('Revise os dados'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 6 de 6'), findsOneWidget);
      expect(find.text('Trabalho de transições'), findsOneWidget);
      expect(find.text('Encerrar com 5 minutos de passo'), findsOneWidget);
      expect(find.text('Transições trote-galope'), findsOneWidget);
      expect(find.text('Aquecimento ao passo'), findsOneWidget);

      // Edita o título inline
      await tester.tap(find.byTooltip('Editar Título'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('training-review-title')),
        'Treino de Equilíbrio Avançado',
      );
      await tester.pump();

      // Remove a primeira orientação
      final removeGuidelineButton = find.byKey(
        const ValueKey('remove-training-review-guideline-0'),
      );
      await tester.ensureVisible(removeGuidelineButton);
      await tester.tap(removeGuidelineButton);
      await tester.pump();

      expect(find.text('Encerrar com 5 minutos de passo'), findsNothing);
      expect(
        find.text('Descansar 3 minutos entre cada exercício'),
        findsOneWidget,
      );

      // Remove o segundo exercício selecionado
      final removeExerciseButton = find.byKey(
        const ValueKey('remove-training-review-exercise-1'),
      );
      await tester.ensureVisible(removeExerciseButton);
      await tester.tap(removeExerciseButton);
      await tester.pump();

      expect(find.text('Aquecimento ao passo'), findsNothing);
      expect(find.text('Transições trote-galope'), findsOneWidget);

      final submitButton = find.byKey(
        const Key('submit-training-registration'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(submittedDraft, isNotNull);
      expect(submittedDraft!.title, 'Treino de Equilíbrio Avançado');
      expect(submittedDraft!.guidelines, [
        'Descansar 3 minutos entre cada exercício',
      ]);
      expect(submittedDraft!.selectedExercises, hasLength(1));
      expect(submittedDraft!.selectedExercises.first.id, 'ex-specific-1');
    },
  );

  testWidgets(
    'blocks submission when all guidelines are removed and shows error',
    (tester) async {
      var submitted = false;

      await tester.pumpWidget(
        buildApp(
          TrainingConfirmationScreen(controller: TrainingRegistrationController(galleryRepository: const LocalTrainingExerciseGalleryRepository(), horseRepository: const LocalTrainerLinkedHorseRepository(), registrationRepository: const LocalTrainingRegistrationRepository()),
            draft: const TrainingRegistrationDraft(
              title: 'Treino A',
              description: 'Descrição do treino A',
              estimatedDurationMinutes: 30,
              guidelines: ['Orientação 1'],
              selectedExercises: [
                TrainingExerciseItem(
                  id: 'ex-generic-1',
                  name: 'Aquecimento ao passo',
                  estimatedDurationMinutes: 10,
                  exerciseType: ExerciseType.generic,
                ),
              ],
            ),
            onSubmitted: (_) => submitted = true,
          ),
        ),
      );

      final removeGuideline = find.byKey(
        const ValueKey('remove-training-review-guideline-0'),
      );
      await tester.ensureVisible(removeGuideline);
      await tester.tap(removeGuideline);
      await tester.pump();

      expect(find.text('Nenhuma orientação adicionada.'), findsOneWidget);

      final submitButton = find.byKey(
        const Key('submit-training-registration'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(submitted, isFalse);
      expect(
        find.text(
          'Adicione pelo menos uma orientação para cadastrar o treinamento.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'blocks submission when all selected exercises are removed and shows error',
    (tester) async {
      var submitted = false;

      await tester.pumpWidget(
        buildApp(
          TrainingConfirmationScreen(controller: TrainingRegistrationController(galleryRepository: const LocalTrainingExerciseGalleryRepository(), horseRepository: const LocalTrainerLinkedHorseRepository(), registrationRepository: const LocalTrainingRegistrationRepository()),
            draft: const TrainingRegistrationDraft(
              title: 'Treino A',
              description: 'Descrição do treino A',
              estimatedDurationMinutes: 30,
              guidelines: ['Orientação 1'],
              selectedExercises: [
                TrainingExerciseItem(
                  id: 'ex-generic-1',
                  name: 'Aquecimento ao passo',
                  estimatedDurationMinutes: 10,
                  exerciseType: ExerciseType.generic,
                ),
              ],
            ),
            onSubmitted: (_) => submitted = true,
          ),
        ),
      );

      final removeExercise = find.byKey(
        const ValueKey('remove-training-review-exercise-0'),
      );
      await tester.ensureVisible(removeExercise);
      await tester.tap(removeExercise);
      await tester.pump();

      expect(find.text('Nenhum exercício selecionado.'), findsOneWidget);

      final submitButton = find.byKey(
        const Key('submit-training-registration'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(submitted, isFalse);
      expect(
        find.text(
          'Adicione pelo menos um exercício para cadastrar o treinamento.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'submits training through controller and pops registration flow route',
    (tester) async {
      final spyRepository = _SpyTrainingRegistrationRepository();
      final controller = TrainingRegistrationController(galleryRepository: const LocalTrainingExerciseGalleryRepository(), horseRepository: const LocalTrainerLinkedHorseRepository(),
        registrationRepository: spyRepository,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(
                          name: TrainingRegistrationFlowRoute.routeName,
                        ),
                        builder: (_) => TrainingConfirmationScreen(
                          draft: sampleDraft,
                          controller: controller,
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir revisão'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir revisão'));
      await tester.pumpAndSettle();

      expect(find.byType(TrainingConfirmationScreen), findsOneWidget);

      final submitButton = find.byKey(
        const Key('submit-training-registration'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(spyRepository.submittedDraft, isNotNull);
      expect(spyRepository.submittedDraft!.title, 'Trabalho de transições');
      expect(find.byType(TrainingConfirmationScreen), findsNothing);
      expect(find.text('Abrir revisão'), findsOneWidget);
    },
  );
}
