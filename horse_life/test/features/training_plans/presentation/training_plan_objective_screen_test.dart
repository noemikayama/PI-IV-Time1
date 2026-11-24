// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa 2 de 7 (Objetivo do plano), cobrindo
// validação obrigatória e navegação para Seleção do animal.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/training_plans/application/states/training_plan_registration_draft.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_horse_screen.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_objective_screen.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  testWidgets('validates objective and navigates to horse selection screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const TrainingPlanObjectiveScreen(
          draft: TrainingPlanRegistrationDraft(title: 'Plano Base'),
        ),
      ),
    );

    expect(find.text('Objetivo do plano'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 2 de 7'), findsOneWidget);

    final continueButton = find.byKey(
      const Key('continue-training-plan-objective'),
    );
    await tester.tap(continueButton);
    await tester.pump();
    expect(find.text('Preencha este campo.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('training-plan-objective-input')),
      'Ganhar condicionamento para percursos de 1,00 m.',
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(TrainingPlanHorseScreen), findsOneWidget);
    expect(find.text('Seleção do animal'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 3 de 7'), findsOneWidget);
  });
}
