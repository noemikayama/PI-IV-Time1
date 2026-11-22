// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa de seleção do cavalo vinculado e de
// transição para a definição do nome na segunda etapa do fluxo específico.
// -----------------------------------------------------------------------------

import '../../../support/features/exercises/data/repositories/local_trainer_linked_horse_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_horse_screen.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_name_screen.dart';

void main() {
  Widget buildApp(ExerciseHorseScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets('displays linked horses in dropdown and advances to step 2 of 8', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const ExerciseHorseScreen(horseRepository: const LocalTrainerLinkedHorseRepository())));
    await tester.pumpAndSettle();

    expect(find.text('Cavalo vinculado'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 8'), findsOneWidget);
    expect(find.text('Calvino'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-horse-dropdown')));
    await tester.pumpAndSettle();

    expect(find.text('Selecionar cavalo'), findsOneWidget);
    expect(find.text('Trovão'), findsOneWidget);

    await tester.tap(find.text('Trovão').last);
    await tester.pumpAndSettle();

    final continueButton = find.byKey(const Key('continue-exercise-horse'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(ExerciseNameScreen), findsOneWidget);
    expect(find.text('Nome do exercício'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 2 de 8'), findsOneWidget);
  });
}
