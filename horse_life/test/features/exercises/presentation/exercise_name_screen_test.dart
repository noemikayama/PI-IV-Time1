// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa de nome do exercício nos fluxos
// genérico (etapa 1 de 7) e específico (etapa 2 de 8).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/application/states/exercise_registration_draft.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_name_screen.dart';

void main() {
  Widget buildApp(ExerciseNameScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets('validates non-empty exercise name and updates generic draft', (
    tester,
  ) async {
    ExerciseRegistrationDraft? receivedDraft;

    await tester.pumpWidget(
      buildApp(
        ExerciseNameScreen.generic(
          onContinue: (draft) => receivedDraft = draft,
        ),
      ),
    );

    expect(find.text('Nome do exercício'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 7'), findsOneWidget);

    final continueButton = find.byKey(const Key('continue-exercise-name'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.text('Preencha este campo.'), findsOneWidget);
    expect(receivedDraft, isNull);

    await tester.enterText(find.byType(TextFormField), '  Trote Alongado  ');
    await tester.tap(continueButton);
    await tester.pump();

    expect(receivedDraft, isA<GenericExerciseRegistrationDraft>());
    expect(receivedDraft?.name, 'Trote Alongado');
  });

  testWidgets('preserves selected horse when updating specific draft on step 2 of 8', (
    tester,
  ) async {
    ExerciseRegistrationDraft? receivedDraft;
    const calvino = TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino');

    await tester.pumpWidget(
      buildApp(
        ExerciseNameScreen.specific(
          draft: const SpecificExerciseRegistrationDraft(horse: calvino),
          onContinue: (draft) => receivedDraft = draft,
        ),
      ),
    );

    expect(find.bySemanticsLabel('Etapa 2 de 8'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Transição Galope');
    final continueButton = find.byKey(const Key('continue-exercise-name'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(receivedDraft, isA<SpecificExerciseRegistrationDraft>());
    final specificDraft = receivedDraft! as SpecificExerciseRegistrationDraft;
    expect(specificDraft.horse, calvino);
    expect(specificDraft.name, 'Transição Galope');
  });
}
