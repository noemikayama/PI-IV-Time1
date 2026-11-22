// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa 5 de 6 (Duração estimada do
// treinamento), verificando exibição da soma dos exercícios selecionados,
// filtro numérico, validação entre 1 e 480 minutos e avanço para a revisão.
// -----------------------------------------------------------------------------

import '../../../support/features/trainings/data/repositories/local_training_registration_repository.dart';
import '../../../support/features/trainings/data/repositories/local_training_exercise_gallery_repository.dart';
import '../../../support/features/exercises/data/repositories/local_trainer_linked_horse_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/trainings/application/controllers/training_registration_controller.dart';
import 'package:horse_life/features/trainings/application/states/training_registration_draft.dart';
import 'package:horse_life/features/trainings/data/models/training_exercise_item.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_confirmation_screen.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_duration_screen.dart';

class _StubDurationTrainingRegistrationRepository
    extends LocalTrainingRegistrationRepository {
  @override
  Future<int> sumExerciseDurations({
    required List<TrainingExerciseItem> exercises,
  }) async {
    return 35;
  }
}

void main() {
  Widget buildApp(TrainingDurationScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  const sampleDraft = TrainingRegistrationDraft(
    title: 'Trabalho de transições',
    description: 'Sessão focada em equilíbrio.',
    selectedExercises: [
      TrainingExerciseItem(
        id: 'ex-1',
        name: 'Aquecimento ao passo',
        estimatedDurationMinutes: 10,
        exerciseType: ExerciseType.generic,
      ),
      TrainingExerciseItem(
        id: 'ex-2',
        name: 'Transições trote-galope',
        estimatedDurationMinutes: 20,
        exerciseType: ExerciseType.generic,
      ),
    ],
  );

  testWidgets(
    'displays total duration of selected exercises, validates range 1..480 and advances to confirmation screen',
    (tester) async {
      final controller = TrainingRegistrationController(galleryRepository: const LocalTrainingExerciseGalleryRepository(), horseRepository: const LocalTrainerLinkedHorseRepository(),
        registrationRepository: _StubDurationTrainingRegistrationRepository(),
      );

      await tester.pumpWidget(
        buildApp(
          TrainingDurationScreen(draft: sampleDraft, controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Duração estimada'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 5 de 6'), findsOneWidget);
      expect(
        find.textContaining('Tempo total dos exercícios selecionados: 35 min'),
        findsOneWidget,
      );

      final durationField = find.byKey(const Key('training-duration-input'));
      await tester.enterText(durationField, 'abc500min');
      await tester.pump();

      final textFieldController =
          tester.widget<TextFormField>(find.byType(TextFormField)).controller!;
      expect(textFieldController.text, '500');

      final continueButton = find.byKey(const Key('continue-training-duration'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Informe uma duração válida entre 1 e 480 minutos.'),
        findsOneWidget,
      );
      expect(find.byType(TrainingConfirmationScreen), findsNothing);

      // Informa tempo inferior à soma dos exercícios (35 min)
      await tester.enterText(durationField, '30');
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(
        find.text('A duração não pode ser menor que a soma dos exercícios (35 min).'),
        findsOneWidget,
      );
      expect(find.byType(TrainingConfirmationScreen), findsNothing);

      await tester.enterText(durationField, '45');
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(TrainingConfirmationScreen), findsOneWidget);
      expect(find.text('Revise os dados'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 6 de 6'), findsOneWidget);
    },
  );
}
