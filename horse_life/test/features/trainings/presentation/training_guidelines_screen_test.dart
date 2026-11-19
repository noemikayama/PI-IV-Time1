// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa 4 de 6 (Orientações do treinamento),
// cobrindo adição via modal, prevenção de duplicatas, remoção e avanço para a
// etapa de duração estimada (inclusive sem orientações opcionais).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/trainings/application/states/training_registration_draft.dart';
import 'package:horse_life/features/trainings/data/models/training_exercise_item.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_duration_screen.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_guidelines_screen.dart';
import 'package:horse_life/features/trainings/presentation/widgets/add_training_guideline_dialog.dart';

void main() {
  Widget buildApp(TrainingGuidelinesScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  const sampleDraft = TrainingRegistrationDraft(
    title: 'Trabalho de transições',
    description: 'Sessão focada em equilíbrio.',
    selectedExercises: [
      TrainingExerciseItem(
        id: 'ex-1',
        name: 'Aquecimento ao passo',
        estimatedDurationMinutes: 10,
        exerciseType: ExerciseType.generic,
      ),
    ],
  );

  testWidgets(
    'adds, prevents duplicate, removes guidelines and advances to duration screen',
    (tester) async {
      await tester.pumpWidget(
        buildApp(const TrainingGuidelinesScreen(draft: sampleDraft)),
      );

      expect(find.text('Orientações do\ntreinamento'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 4 de 6'), findsOneWidget);
      expect(find.text('Adicionar orientação'), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-training-guideline')));
      await tester.pumpAndSettle();

      expect(find.byType(AddTrainingGuidelineDialog), findsOneWidget);
      expect(find.text('Adicionar\norientação'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('training-guideline-input')),
        'Encerrar com 5 minutos de passo',
      );
      await tester.tap(find.byKey(const Key('save-training-guideline')));
      await tester.pumpAndSettle();

      expect(find.text('Encerrar com 5 minutos de passo'), findsOneWidget);

      // Tenta adicionar orientação duplicada (case-insensitive)
      await tester.tap(find.byKey(const Key('add-training-guideline')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('training-guideline-input')),
        'encerrar com 5 minutos de passo',
      );
      await tester.tap(find.byKey(const Key('save-training-guideline')));
      await tester.pumpAndSettle();

      expect(find.text('Essa orientação já foi adicionada.'), findsOneWidget);

      // Adiciona segunda orientação válida
      await tester.tap(find.byKey(const Key('add-training-guideline')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('training-guideline-input')),
        'Descansar 3 minutos entre cada exercício',
      );
      await tester.tap(find.byKey(const Key('save-training-guideline')));
      await tester.pumpAndSettle();

      expect(
        find.text('Descansar 3 minutos entre cada exercício'),
        findsOneWidget,
      );

      // Remove a primeira orientação
      await tester.tap(find.byKey(const ValueKey('remove-training-guideline-0')));
      await tester.pumpAndSettle();

      expect(find.text('Encerrar com 5 minutos de passo'), findsNothing);
      expect(
        find.text('Descansar 3 minutos entre cada exercício'),
        findsOneWidget,
      );

      final continueButton = find.byKey(
        const Key('continue-training-guidelines'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(TrainingDurationScreen), findsOneWidget);
      expect(find.text('Duração estimada'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 5 de 6'), findsOneWidget);
    },
  );

  testWidgets(
    'blocks navigation and displays snackbar if no guidelines have been added',
    (tester) async {
      TrainingRegistrationDraft? nextDraft;

      await tester.pumpWidget(
        buildApp(
          TrainingGuidelinesScreen(
            draft: sampleDraft,
            onContinue: (draft) => nextDraft = draft,
          ),
        ),
      );

      final continueButton = find.byKey(
        const Key('continue-training-guidelines'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(nextDraft, isNull);
      expect(find.byType(TrainingDurationScreen), findsNothing);
      expect(
        find.text('Adicione pelo menos uma orientação para continuar.'),
        findsOneWidget,
      );
    },
  );
}
