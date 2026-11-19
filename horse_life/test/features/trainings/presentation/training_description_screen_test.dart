// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes de widget da etapa 2 de 6 (Descrição do
// treinamento), cobrindo validação de preenchimento e navegação para seleção
// de exercícios.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/trainings/application/states/training_registration_draft.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_description_screen.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_exercises_screen.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  testWidgets('validates description and navigates to exercise selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const TrainingDescriptionScreen(
          draft: TrainingRegistrationDraft(title: 'Trabalho de transições'),
        ),
      ),
    );

    expect(find.text('Descrição do\ntreinamento'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 2 de 6'), findsOneWidget);

    final continueButton = find.byKey(
      const Key('continue-training-description'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.text('Preencha este campo.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('training-description-input')),
      'Sessão focada em equilíbrio e transições.',
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(TrainingExercisesScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 3 de 6'), findsOneWidget);
  });
}
