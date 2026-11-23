// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do teste unitário de widget para validar o alinhamento e
// ausência de corte lateral ao expandir TrainingAgendaFloatingMenu no canto
// inferior direito de um Scaffold.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/training/presentation/widgets/training_agenda_floating_menu.dart';

void main() {
  testWidgets('mantém opções alinhadas à direita acima do FAB sem corte lateral', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(440, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var plansTapped = 0;
    var trainingTapped = 0;
    var exerciseTapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          floatingActionButton: TrainingAgendaFloatingMenu(
            onCreatePlan: () => plansTapped++,
            onCreateTraining: () => trainingTapped++,
            onCreateExercise: () => exerciseTapped++,
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trainer-agenda-fab')), findsOneWidget);
    expect(find.byKey(const Key('trainer-agenda-fab-options')), findsNothing);

    await tester.tap(find.byKey(const Key('trainer-agenda-fab')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trainer-agenda-fab-options')), findsOneWidget);
    expect(find.text('Plano de treinos'), findsOneWidget);
    expect(find.text('Treinamento'), findsOneWidget);
    expect(find.text('Exercício'), findsOneWidget);

    final fabRect = tester.getRect(find.byKey(const Key('trainer-agenda-fab')));
    final optionsRect = tester.getRect(
      find.byKey(const Key('trainer-agenda-fab-options')),
    );

    expect(optionsRect.left, greaterThanOrEqualTo(0));
    expect((optionsRect.right - fabRect.right).abs(), lessThan(1.0));
    expect(optionsRect.bottom, lessThanOrEqualTo(fabRect.top));

    await tester.tap(find.byKey(const Key('trainer-agenda-create-plan')));
    await tester.pumpAndSettle();
    expect(plansTapped, 1);

    await tester.tap(find.byKey(const Key('trainer-agenda-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trainer-agenda-create-training')));
    await tester.pumpAndSettle();
    expect(trainingTapped, 1);

    await tester.tap(find.byKey(const Key('trainer-agenda-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trainer-agenda-create-exercise')));
    await tester.pumpAndSettle();
    expect(exerciseTapped, 1);
  });
}
