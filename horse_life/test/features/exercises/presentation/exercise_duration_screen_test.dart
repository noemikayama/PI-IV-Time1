// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa de duração padrão do exercício,
// verificando o filtro numérico e a atualização do draft nos fluxos genérico
// (etapa 4 de 7) e específico (etapa 5 de 8).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/application/states/exercise_registration_draft.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_duration_screen.dart';

void main() {
  Widget buildApp(ExerciseDurationScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets(
    'filters non-numeric characters and stores duration in minutes on step 4 of 7',
    (tester) async {
      ExerciseRegistrationDraft? receivedDraft;

      await tester.pumpWidget(
        buildApp(
          ExerciseDurationScreen(
            draft: const GenericExerciseRegistrationDraft(
              name: 'Trote Alongado',
              description: 'Descrição',
            ),
            onContinue: (draft) => receivedDraft = draft,
          ),
        ),
      );

      expect(find.text('Duração padrão'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 4 de 7'), findsOneWidget);

      final textField = find.byType(TextFormField);
      await tester.enterText(textField, 'abc15min');
      await tester.pump();

      final controller = tester.widget<TextFormField>(textField).controller!;
      expect(controller.text, '15');

      final continueButton = find.byKey(const Key('continue-exercise-duration'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();

      expect(receivedDraft?.defaultDurationMinutes, 15);
    },
  );

  testWidgets(
    'displays step 5 of 8 when specific draft is provided',
    (tester) async {
      const calvino = TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino');

      await tester.pumpWidget(
        buildApp(
          const ExerciseDurationScreen(
            draft: SpecificExerciseRegistrationDraft(
              horse: calvino,
              name: 'Transição Galope',
              description: 'Descrição',
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Etapa 5 de 8'), findsOneWidget);
    },
  );
}
