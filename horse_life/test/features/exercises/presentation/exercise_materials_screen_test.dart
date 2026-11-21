// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa de materiais necessários e quantidades,
// validando a adição pelo modal (+ / -), remoção e avanço para mídias auxiliares.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/application/states/exercise_material.dart';
import 'package:horse_life/features/exercises/application/states/exercise_registration_draft.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_materials_screen.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_media_screen.dart';

void main() {
  Widget buildApp(ExerciseMaterialsScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets(
    'adds material with incremented quantity, removes item and navigates to media screen on step 5 of 7',
    (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ExerciseMaterialsScreen(
            draft: GenericExerciseRegistrationDraft(
              name: 'Trote com Cavaletes',
              description: 'Descrição',
              defaultDurationMinutes: 20,
            ),
          ),
        ),
      );

      expect(find.text('Materiais necessários'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 5 de 7'), findsOneWidget);

      await tester.tap(find.byKey(const Key('add-exercise-material')));
      await tester.pumpAndSettle();

      expect(find.text('Adicionar\nmaterial'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('exercise-material-name-input')),
        'Cavalete',
      );
      await tester.tap(
        find.byKey(const Key('increment-exercise-material-quantity')),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('increment-exercise-material-quantity')),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('save-exercise-material')));
      await tester.pumpAndSettle();

      expect(find.text('(3) Cavalete'), findsOneWidget);

      final continueButton = find.byKey(
        const Key('continue-exercise-materials'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseMediaScreen), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 6 de 7'), findsOneWidget);
    },
  );

  testWidgets(
    'displays step 6 of 8 for specific draft and allows removing pre-existing material',
    (tester) async {
      const calvino = TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino');

      await tester.pumpWidget(
        buildApp(
          const ExerciseMaterialsScreen(
            draft: SpecificExerciseRegistrationDraft(
              horse: calvino,
              name: 'Passagem de Vara',
              description: 'Descrição',
              defaultDurationMinutes: 15,
              materials: [ExerciseMaterial(name: 'Vara', quantity: 2)],
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Etapa 6 de 8'), findsOneWidget);
      expect(find.text('(2) Vara'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('remove-exercise-material-0')));
      await tester.pump();

      expect(find.text('(2) Vara'), findsNothing);
    },
  );
}
