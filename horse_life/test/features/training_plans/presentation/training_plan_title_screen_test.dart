// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa 1 de 7 (Título do plano), cobrindo
// validação de tamanho (3 a 80 caracteres) e avanço para Objetivo do plano.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_objective_screen.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_title_screen.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  testWidgets('validates title bounds and navigates to objective screen', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const TrainingPlanTitleScreen()));

    expect(find.text('Título do plano'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 7'), findsOneWidget);

    final continueButton = find.byKey(const Key('continue-training-plan-title'));
    await tester.tap(continueButton);
    await tester.pump();
    expect(find.text('Preencha este campo.'), findsOneWidget);

    final titleField = find.byKey(const Key('training-plan-title-input'));
    await tester.enterText(titleField, 'AB');
    await tester.tap(continueButton);
    await tester.pump();
    expect(
      find.text('O título deve ter entre 3 e 80 caracteres.'),
      findsOneWidget,
    );

    await tester.enterText(
      titleField,
      '  Condicionamento para percursos de 1,00 m  ',
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(TrainingPlanObjectiveScreen), findsOneWidget);
    expect(find.text('Objetivo do plano'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 2 de 7'), findsOneWidget);
  });
}
