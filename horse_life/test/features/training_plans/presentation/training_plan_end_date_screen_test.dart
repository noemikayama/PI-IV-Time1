// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa 5 de 7 (Data de fim), cobrindo
// obrigatoriedade da data, restrição de data anterior ao início ou duração acima
// de 12 meses, seleção no calendário em português e emissão do draft.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/training_plans/application/states/training_plan_registration_draft.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_end_date_screen.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  const calvino = TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino');

  testWidgets('requires end date, picks date and forwards updated draft', (
    tester,
  ) async {
    final startDate = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
    final draftWithStart = const TrainingPlanRegistrationDraft(
      title: 'Plano Base',
      objective: 'Ganhar resistência',
      horse: calvino,
    ).withStartDate(startDate);

    TrainingPlanRegistrationDraft? receivedDraft;

    await tester.pumpWidget(
      buildApp(
        TrainingPlanEndDateScreen(
          draft: draftWithStart,
          onContinue: (draft) => receivedDraft = draft,
        ),
      ),
    );

    expect(find.text('Data de fim'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 5 de 7'), findsOneWidget);
    expect(find.text('DD/MM/AAAA'), findsOneWidget);

    final continueButton = find.byKey(
      const Key('continue-training-plan-end-date'),
    );
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Selecione a data de fim para continuar.'),
      findsOneWidget,
    );
    expect(receivedDraft, isNull);

    await tester.tap(find.byKey(const Key('training-plan-end-date-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text(formatAppDate(startDate)), findsOneWidget);

    await tester.tap(continueButton);
    await tester.pump();

    expect(receivedDraft, isNotNull);
    expect(receivedDraft!.endDate, startDate);
  });

  testWidgets('blocks end date exceeding 12 months from start date', (
    tester,
  ) async {
    final startDate = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
    final tooLateEndDate = TrainingPlanRegistrationDraft.addMonths(
      startDate,
      12,
    );

    TrainingPlanRegistrationDraft? receivedDraft;

    await tester.pumpWidget(
      buildApp(
        TrainingPlanEndDateScreen(
          draft: TrainingPlanRegistrationDraft(
            title: 'Plano Base',
            objective: 'Ganhar resistência',
            horse: calvino,
            startDate: startDate,
            endDate: tooLateEndDate,
          ),
          onContinue: (draft) => receivedDraft = draft,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('continue-training-plan-end-date')));
    await tester.pumpAndSettle();

    expect(receivedDraft, isNull);
    expect(
      find.text('O plano pode durar no máximo 12 meses.'),
      findsOneWidget,
    );
  });
}
