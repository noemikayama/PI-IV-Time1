// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes de widget da etapa 1 de 6 (Título do treinamento),
// validando barra de progresso, validações de tamanho e avanço para a descrição.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/trainings/application/states/training_registration_draft.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_description_screen.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_title_screen.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  testWidgets('validates title rules and updates draft on step 1 of 6', (
    tester,
  ) async {
    TrainingRegistrationDraft? receivedDraft;

    await tester.pumpWidget(
      buildApp(
        TrainingTitleScreen(
          onContinue: (draft) => receivedDraft = draft,
        ),
      ),
    );

    expect(find.text('Título do treinamento'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 6'), findsOneWidget);
    expect(find.byKey(const Key('training-progress-segment-6')), findsOneWidget);

    final continueButton = find.byKey(const Key('continue-training-title'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.text('Preencha este campo.'), findsOneWidget);
    expect(receivedDraft, isNull);

    await tester.enterText(find.byType(TextFormField), 'Ab');
    await tester.tap(continueButton);
    await tester.pump();

    expect(
      find.text('O título deve ter entre 3 e 80 caracteres.'),
      findsOneWidget,
    );
    expect(receivedDraft, isNull);

    await tester.enterText(
      find.byType(TextFormField),
      '  Trabalho de transições  ',
    );
    await tester.tap(continueButton);
    await tester.pump();

    expect(receivedDraft?.title, 'Trabalho de transições');
  });

  testWidgets('navigates to TrainingDescriptionScreen when onContinue is null', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const TrainingTitleScreen()));

    await tester.enterText(
      find.byType(TextFormField),
      'Treino de resistência',
    );
    final continueButton = find.byKey(const Key('continue-training-title'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(TrainingDescriptionScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 2 de 6'), findsOneWidget);
  });
}
