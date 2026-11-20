// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa 4 de 7 (Data de início), cobrindo
// obrigatoriedade da data, bloqueio de datas passadas, seleção no calendário
// em português e avanço para a etapa de data de fim.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/training_plans/application/states/training_plan_registration_draft.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_end_date_screen.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_start_date_screen.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  const calvino = TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino');

  const baseDraft = TrainingPlanRegistrationDraft(
    title: 'Plano Base',
    objective: 'Ganhar resistência',
    horse: calvino,
  );

  testWidgets('requires start date and advances to end date screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(const TrainingPlanStartDateScreen(draft: baseDraft)),
    );

    expect(find.text('Data de início'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 4 de 7'), findsOneWidget);
    expect(find.text('DD/MM/AAAA'), findsOneWidget);

    final continueButton = find.byKey(
      const Key('continue-training-plan-start-date'),
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Selecione a data de início para continuar.'),
      findsOneWidget,
    );
    expect(find.byType(TrainingPlanEndDateScreen), findsNothing);

    await tester.tap(find.byKey(const Key('training-plan-start-date-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final today = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
    expect(find.text(formatAppDate(today)), findsOneWidget);

    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(TrainingPlanEndDateScreen), findsOneWidget);
    expect(find.text('Data de fim'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 5 de 7'), findsOneWidget);
  });

  testWidgets('blocks continuing when initial draft has past start date', (
    tester,
  ) async {
    final yesterday = TrainingPlanRegistrationDraft.dateOnly(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    await tester.pumpWidget(
      buildApp(
        TrainingPlanStartDateScreen(
          draft: baseDraft.withStartDate(yesterday),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('continue-training-plan-start-date')));
    await tester.pumpAndSettle();

    expect(
      find.text('A data de início deve ser hoje ou uma data futura.'),
      findsOneWidget,
    );
    expect(find.byType(TrainingPlanEndDateScreen), findsNothing);
  });
}
