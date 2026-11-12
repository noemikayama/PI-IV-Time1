// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Inclusão de teste validando o bloqueio de avanço quando não há
// orientações adicionadas.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa de orientações do exercício, cobrindo
// a adição pelo modal, remoção individual e transição para duração padrão.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/application/states/exercise_registration_draft.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_duration_screen.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_guidelines_screen.dart';
import 'package:horse_life/features/exercises/presentation/widgets/add_exercise_guideline_dialog.dart';

void main() {
  Widget buildApp(ExerciseGuidelinesScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets(
    'adds and removes guidelines via modal and advances to duration screen',
    (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ExerciseGuidelinesScreen(
            draft: GenericExerciseRegistrationDraft(
              name: 'Trote Alongado',
              description: 'Alternar trote e galope',
            ),
          ),
        ),
      );

      expect(find.text('Orientações do exercício'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 3 de 7'), findsOneWidget);
      expect(find.text('Adicionar orientação'), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-exercise-guideline')));
      await tester.pumpAndSettle();

      expect(find.byType(AddExerciseGuidelineDialog), findsOneWidget);
      expect(find.text('Adicionar\norientação'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('exercise-guideline-input')),
        'Manter contato leve com as rédeas',
      );
      await tester.tap(find.byKey(const Key('save-exercise-guideline')));
      await tester.pumpAndSettle();

      expect(find.text('Manter contato leve com as rédeas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-exercise-guideline')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('exercise-guideline-input')),
        'Aumentar o ritmo progressivamente',
      );
      await tester.tap(find.byKey(const Key('save-exercise-guideline')));
      await tester.pumpAndSettle();

      expect(find.text('Aumentar o ritmo progressivamente'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('remove-exercise-guideline-0')));
      await tester.pumpAndSettle();

      expect(find.text('Manter contato leve com as rédeas'), findsNothing);
      expect(find.text('Aumentar o ritmo progressivamente'), findsOneWidget);

      final continueButton = find.byKey(
        const Key('continue-exercise-guidelines'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseDurationScreen), findsOneWidget);
      expect(find.text('Duração padrão'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 4 de 7'), findsOneWidget);
    },
  );

  testWidgets(
    'blocks navigation and displays snackbar if no guidelines have been added',
    (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ExerciseGuidelinesScreen(
            draft: GenericExerciseRegistrationDraft(
              name: 'Trote Alongado',
              description: 'Alternar trote e galope',
            ),
          ),
        ),
      );

      final continueButton = find.byKey(
        const Key('continue-exercise-guidelines'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseDurationScreen), findsNothing);
      expect(
        find.text('Adicione pelo menos uma orientação para continuar.'),
        findsOneWidget,
      );
    },
  );
}
