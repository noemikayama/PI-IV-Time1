// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa de descrição detalhada do exercício
// nos fluxos genérico (etapa 2 de 7) e específico (etapa 3 de 8).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/application/states/exercise_registration_draft.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_description_screen.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_guidelines_screen.dart';

void main() {
  Widget buildApp(ExerciseDescriptionScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets(
    'validates description and navigates to guidelines on step 2 of 7 for generic exercise',
    (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ExerciseDescriptionScreen(
            draft: GenericExerciseRegistrationDraft(name: 'Trote Alongado'),
          ),
        ),
      );

      expect(find.text('Descrição do exercício'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 2 de 7'), findsOneWidget);

      final continueButton = find.byKey(
        const Key('continue-exercise-description'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();

      expect(find.text('Preencha este campo.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('exercise-description-input')),
        '  Alternar trote e galope em intervalos definidos  ',
      );
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseGuidelinesScreen), findsOneWidget);
      expect(find.text('Orientações do exercício'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 3 de 7'), findsOneWidget);
    },
  );

  testWidgets(
    'shows step 3 of 8 for specific exercise and preserves linked horse',
    (tester) async {
      ExerciseRegistrationDraft? receivedDraft;
      const calvino = TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino');

      await tester.pumpWidget(
        buildApp(
          ExerciseDescriptionScreen(
            draft: const SpecificExerciseRegistrationDraft(
              horse: calvino,
              name: 'Transição Galope',
            ),
            onContinue: (draft) => receivedDraft = draft,
          ),
        ),
      );

      expect(find.bySemanticsLabel('Etapa 3 de 8'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('exercise-description-input')),
        'Exercício focado em impulsão.',
      );
      final continueButton = find.byKey(
        const Key('continue-exercise-description'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();

      expect(receivedDraft, isA<SpecificExerciseRegistrationDraft>());
      final specific = receivedDraft! as SpecificExerciseRegistrationDraft;
      expect(specific.horse, calvino);
      expect(specific.name, 'Transição Galope');
      expect(specific.description, 'Exercício focado em impulsão.');
    },
  );
}
