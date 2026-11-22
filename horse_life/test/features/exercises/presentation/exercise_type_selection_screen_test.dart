// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da tela de seleção do tipo de exercício,
// cobrindo o bloqueio por ausência de cavalos vinculados e o direcionamento
// para as trilhas de 8 etapas (específico) e 7 etapas (genérico).
// -----------------------------------------------------------------------------

import '../../../support/features/exercises/data/repositories/local_trainer_linked_horse_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_horse_screen.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_name_screen.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_type_selection_screen.dart';
import 'package:horse_life/features/exercises/presentation/widgets/no_linked_horses_dialog.dart';

void main() {
  Widget buildApp(ExerciseTypeSelectionScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets('shows exercise privacy options and explanatory rows', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const ExerciseTypeSelectionScreen(horseRepository: const LocalTrainerLinkedHorseRepository())));

    expect(find.text('Tipo de exercício'), findsOneWidget);
    expect(find.textContaining('Antes dos próximos passos'), findsOneWidget);
    expect(find.text('Específico'), findsOneWidget);
    expect(find.textContaining('Exercícios específicos são'), findsOneWidget);
    expect(find.textContaining('Exercícios genéricos são'), findsOneWidget);
    expect(find.text('Seguinte'), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise-type-dropdown')));
    await tester.pumpAndSettle();

    expect(find.text('Selecionar privacidade'), findsOneWidget);
    expect(find.text('Específico'), findsNWidgets(2));
    expect(find.text('Genérico'), findsOneWidget);
  });

  testWidgets(
    'blocks progression and shows modal when specific is selected without linked horses',
    (tester) async {
      await tester.pumpWidget(
        buildApp(
          const ExerciseTypeSelectionScreen(
            horseRepository: LocalTrainerLinkedHorseRepository(horses: []),
          ),
        ),
      );

      final continueButton = find.byKey(
        const Key('continue-exercise-type-selection'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(NoLinkedHorsesDialog), findsOneWidget);
      expect(find.text('Nenhum animal\nvinculado'), findsOneWidget);
      expect(
        find.textContaining(
          'Para poder criar exercícios específicos para um animal',
        ),
        findsOneWidget,
      );
      expect(find.byType(ExerciseHorseScreen), findsNothing);

      await tester.tap(find.byKey(const Key('confirm-no-linked-horses')));
      await tester.pumpAndSettle();

      expect(find.byType(NoLinkedHorsesDialog), findsNothing);
      expect(find.byType(ExerciseTypeSelectionScreen), findsOneWidget);
    },
  );

  testWidgets(
    'opens linked horse selection with 8 progress steps when specific is chosen and horses exist',
    (tester) async {
      await tester.pumpWidget(buildApp(const ExerciseTypeSelectionScreen(horseRepository: const LocalTrainerLinkedHorseRepository())));

      final continueButton = find.byKey(
        const Key('continue-exercise-type-selection'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseHorseScreen), findsOneWidget);
      expect(find.text('Cavalo vinculado'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 1 de 8'), findsOneWidget);
      expect(
        find.byKey(const Key('exercise-progress-segment-8')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'opens exercise name screen directly with 7 progress steps when generic is chosen',
    (tester) async {
      ExerciseType? selectedType;

      await tester.pumpWidget(
        buildApp(
          ExerciseTypeSelectionScreen(
            horseRepository: const LocalTrainerLinkedHorseRepository(
              horses: [],
            ),
            onContinue: (type) => selectedType = type,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('exercise-type-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Genérico').last);
      await tester.pumpAndSettle();

      final continueButton = find.byKey(
        const Key('continue-exercise-type-selection'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(selectedType, ExerciseType.generic);
    },
  );

  testWidgets(
    'navigates to generic exercise name screen with 7 steps when no callback is injected',
    (tester) async {
      await tester.pumpWidget(buildApp(const ExerciseTypeSelectionScreen(horseRepository: const LocalTrainerLinkedHorseRepository())));

      await tester.tap(find.byKey(const Key('exercise-type-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Genérico').last);
      await tester.pumpAndSettle();

      final continueButton = find.byKey(
        const Key('continue-exercise-type-selection'),
      );
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseNameScreen), findsOneWidget);
      expect(find.text('Nome do exercício'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 1 de 7'), findsOneWidget);
      expect(
        find.byKey(const Key('exercise-progress-segment-7')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('exercise-progress-segment-8')),
        findsNothing,
      );
    },
  );
}
