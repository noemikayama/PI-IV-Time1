// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa 3 de 7 (Seleção do animal), cobrindo
// modal quando não há cavalos vinculados, obrigatoriedade da seleção e avanço
// para a etapa de data de início.
// -----------------------------------------------------------------------------

import '../../../support/features/exercises/data/repositories/local_trainer_linked_horse_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import '../../../support/features/exercises/data/mocks/mock_trainer_linked_horses.dart';
import 'package:horse_life/features/exercises/presentation/widgets/no_linked_horses_dialog.dart';
import 'package:horse_life/features/training_plans/application/states/training_plan_registration_draft.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_horse_screen.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_start_date_screen.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  const baseDraft = TrainingPlanRegistrationDraft(
    title: 'Plano Base',
    objective: 'Ganhar resistência',
  );

  testWidgets('requires horse selection and advances to start date screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        TrainingPlanHorseScreen(horseRepository: const LocalTrainerLinkedHorseRepository(),
          draft: baseDraft,
          initialHorses: MockTrainerLinkedHorses.linkedHorses,
        ),
      ),
    );

    expect(find.text('Seleção do animal'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 3 de 7'), findsOneWidget);
    expect(find.text('Selecionar cavalo'), findsOneWidget);

    final continueButton = find.byKey(const Key('continue-training-plan-horse'));
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Selecione um cavalo para continuar.'), findsOneWidget);
    expect(find.byType(TrainingPlanStartDateScreen), findsNothing);

    await tester.tap(find.byKey(const Key('training-plan-horse-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calvino').last);
    await tester.pumpAndSettle();

    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(TrainingPlanStartDateScreen), findsOneWidget);
    expect(find.text('Data de início'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 4 de 7'), findsOneWidget);
  });

  testWidgets('shows dialog when trainer has no linked horses', (tester) async {
    await tester.pumpWidget(
      buildApp(
        const TrainingPlanHorseScreen(horseRepository: const LocalTrainerLinkedHorseRepository(),
          draft: baseDraft,
          initialHorses: MockTrainerLinkedHorses.empty,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('continue-training-plan-horse')));
    await tester.pumpAndSettle();

    expect(find.byType(NoLinkedHorsesDialog), findsOneWidget);
  });
}
