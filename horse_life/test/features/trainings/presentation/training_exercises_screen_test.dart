// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa 3 de 6 (Seleção de exercícios) e do
// bottom sheet da galeria, cobrindo renderização padrão de genéricos, filtro
// condicional por cavalo vinculado, estado vazio, remoção e retorno após criar
// um novo exercício.
// -----------------------------------------------------------------------------

import '../../../support/features/trainings/data/repositories/local_training_registration_repository.dart';
import '../../../support/features/trainings/data/repositories/local_training_exercise_gallery_repository.dart';
import '../../../support/features/exercises/data/repositories/local_trainer_linked_horse_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/application/controllers/exercise_registration_controller.dart';
import '../../../support/features/exercises/data/repositories/mock_exercise_registration_repository.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_type_selection_screen.dart';
import 'package:horse_life/features/trainings/application/controllers/training_registration_controller.dart';
import 'package:horse_life/features/trainings/application/states/training_registration_draft.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_exercises_screen.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  testWidgets('blocks continuing without exercises and shows empty state', (
    tester,
  ) async {
    TrainingRegistrationDraft? submittedDraft;

    await tester.pumpWidget(
      buildApp(
        TrainingExercisesScreen(controller: TrainingRegistrationController(galleryRepository: const LocalTrainingExerciseGalleryRepository(), horseRepository: const LocalTrainerLinkedHorseRepository(), registrationRepository: const LocalTrainingRegistrationRepository()),
          draft: const TrainingRegistrationDraft(
            title: 'Treino A',
            description: 'Descrição A',
          ),
          onContinue: (draft) => submittedDraft = draft,
        ),
      ),
    );

    expect(find.text('Seleção de exercícios'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 3 de 6'), findsOneWidget);
    expect(find.text('Nenhum'), findsOneWidget);

    final continueButton = find.byKey(const Key('continue-training-exercises'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(
      find.text('Adicione pelo menos um exercício para continuar.'),
      findsOneWidget,
    );
    expect(submittedDraft, isNull);
  });

  testWidgets(
    'gallery renders generic exercises by default, filters specific by horse, and supports removal',
    (tester) async {
      TrainingRegistrationDraft? submittedDraft;
      final controller = TrainingRegistrationController(registrationRepository: const LocalTrainingRegistrationRepository(),
        galleryRepository: const LocalTrainingExerciseGalleryRepository(),
        horseRepository: const LocalTrainerLinkedHorseRepository(),
      );

      await tester.pumpWidget(
        buildApp(
          TrainingExercisesScreen(
            draft: const TrainingRegistrationDraft(
              title: 'Treino completo',
              description: 'Descrição',
            ),
            controller: controller,
            onContinue: (draft) => submittedDraft = draft,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open-exercise-gallery-button')));
      await tester.pumpAndSettle();

      // Por padrão, apenas genéricos aparecem (os específicos não).
      expect(find.text('Galeria de exercícios'), findsOneWidget);
      expect(find.text('Aquecimento ao passo'), findsOneWidget);
      expect(find.text('Círculos ao trote'), findsOneWidget);
      expect(find.text('Transições trote-galope'), findsNothing);

      // Seleciona um exercício genérico.
      await tester.tap(
        find.byKey(const ValueKey('gallery-exercise-card-ex-generic-1')),
      );
      await tester.pumpAndSettle();

      // Seleciona o cavalo Calvino no dropdown para exibir específicos dele.
      await tester.tap(
        find.byKey(const Key('exercise-gallery-horse-dropdown')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calvino').last);
      await tester.pumpAndSettle();

      expect(find.text('Transições trote-galope'), findsOneWidget);
      expect(find.text('Aquecimento ao passo'), findsNothing);
      expect(find.text('Espádua adentro'), findsNothing);

      // Seleciona um exercício específico.
      await tester.tap(
        find.byKey(
          const ValueKey('gallery-exercise-card-ex-specific-calvino-1'),
        ),
      );
      await tester.pumpAndSettle();

      // Limpa filtro de cavalo pelo botão X e volta aos genéricos.
      await tester.tap(
        find.byKey(const Key('clear-exercise-gallery-horse-filter')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aquecimento ao passo'), findsOneWidget);

      // Fecha o bottom sheet clicando no backdrop.
      await tester.tapAt(const Offset(20, 40));
      await tester.pumpAndSettle();

      expect(find.text('Aquecimento ao passo'), findsOneWidget);
      expect(find.text('Transições trote-galope'), findsOneWidget);
      expect(find.text('Calvino'), findsOneWidget);

      // Remove o primeiro exercício selecionado.
      await tester.tap(
        find.byKey(const ValueKey('remove-selected-training-exercise-0')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aquecimento ao passo'), findsNothing);
      expect(find.text('Transições trote-galope'), findsOneWidget);

      final continueButton = find.byKey(
        const Key('continue-training-exercises'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();

      expect(submittedDraft?.selectedExercises, hasLength(1));
      expect(
        submittedDraft?.selectedExercises.first.id,
        'ex-specific-calvino-1',
      );
    },
  );

  testWidgets(
    'shows empty gallery state and routes Criar exercício through full flow updating list',
    (tester) async {
      final trainingController = TrainingRegistrationController(registrationRepository: const LocalTrainingRegistrationRepository(),
        galleryRepository: const LocalTrainingExerciseGalleryRepository(
          exercises: [],
        ),
        horseRepository: const LocalTrainerLinkedHorseRepository(horses: []),
      );
      final exerciseController = ExerciseRegistrationController(
        const MockExerciseRegistrationRepository(),
        horseRepository: const LocalTrainerLinkedHorseRepository(horses: []),
      );

      await tester.pumpWidget(
        buildApp(
          TrainingExercisesScreen(
            draft: const TrainingRegistrationDraft(
              title: 'Treino novo',
              description: 'Descrição',
            ),
            controller: trainingController,
            exerciseRegistrationController: exerciseController,
          ),
        ),
      );

      // Abre galeria vazia.
      await tester.tap(find.byKey(const Key('open-exercise-gallery-button')));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum exercício criado'), findsOneWidget);
      expect(
        find.byKey(const Key('gallery-empty-create-exercise-button')),
        findsOneWidget,
      );

      // Clica em Criar exercício dentro do estado vazio da galeria.
      await tester.tap(
        find.byKey(const Key('gallery-empty-create-exercise-button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseTypeSelectionScreen), findsOneWidget);

      // Escolhe Genérico no dropdown do fluxo de criação de exercício.
      await tester.tap(find.byKey(const Key('exercise-type-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Genérico').last);
      await tester.pumpAndSettle();

      final continueType = find.byKey(
        const Key('continue-exercise-type-selection'),
      );
      await tester.ensureVisible(continueType);
      await tester.tap(continueType);
      await tester.pumpAndSettle();

      // Nome
      await tester.enterText(find.byType(TextFormField), 'Galope em círculo');
      final continueName = find.byKey(const Key('continue-exercise-name'));
      await tester.ensureVisible(continueName);
      await tester.tap(continueName);
      await tester.pumpAndSettle();

      // Descrição
      await tester.enterText(
        find.byKey(const Key('exercise-description-input')),
        'Exercício focado em ritmo.',
      );
      final continueDesc = find.byKey(
        const Key('continue-exercise-description'),
      );
      await tester.ensureVisible(continueDesc);
      await tester.tap(continueDesc);
      await tester.pumpAndSettle();

      // Orientações
      await tester.tap(find.byKey(const Key('add-exercise-guideline')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('exercise-guideline-input')),
        'Manter postura alinhada.',
      );
      await tester.tap(find.byKey(const Key('save-exercise-guideline')));
      await tester.pumpAndSettle();
      final continueGuidelines = find.byKey(
        const Key('continue-exercise-guidelines'),
      );
      await tester.ensureVisible(continueGuidelines);
      await tester.tap(continueGuidelines);
      await tester.pumpAndSettle();

      // Duração
      await tester.enterText(find.byType(TextFormField), '12');
      final continueDuration = find.byKey(
        const Key('continue-exercise-duration'),
      );
      await tester.ensureVisible(continueDuration);
      await tester.tap(continueDuration);
      await tester.pumpAndSettle();

      // Materiais
      final continueMaterials = find.byKey(
        const Key('continue-exercise-materials'),
      );
      await tester.ensureVisible(continueMaterials);
      await tester.tap(continueMaterials);
      await tester.pumpAndSettle();

      // Mídias
      final continueMedia = find.byKey(const Key('continue-exercise-media'));
      await tester.ensureVisible(continueMedia);
      await tester.tap(continueMedia);
      await tester.pumpAndSettle();

      // Revisão final e submissão -> deve voltar para TrainingExercisesScreen com a lista atualizada.
      final submitButton = find.byKey(
        const Key('submit-exercise-registration'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.byType(TrainingExercisesScreen), findsOneWidget);
      expect(find.text('Galope em círculo'), findsOneWidget);
      expect(find.text('12 min'), findsOneWidget);

      // Ao abrir a galeria novamente, o exercício recém-criado também aparece nela.
      await tester.tap(find.byKey(const Key('open-exercise-gallery-button')));
      await tester.pumpAndSettle();
      expect(find.text('Galope em círculo'), findsWidgets);
    },
  );
}
