// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa de mídias auxiliares, validando a
// seleção direta pelo explorador de arquivos (sem modal intermediário),
// diferenciação entre imagens e vídeos, remoção e avanço para a revisão.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/application/states/exercise_registration_draft.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_confirmation_screen.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_media_screen.dart';

void main() {
  Widget buildApp(ExerciseMediaScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets(
    'picks image and video files directly without intermediate modal on step 6 of 7 and advances to review',
    (tester) async {
      final fakeFiles = <XFile>[
        XFile.fromData(
          Uint8List.fromList([1, 2, 3]),
          name: 'imagem_1.png',
          path: '/tmp/imagem_1.png',
          mimeType: 'image/png',
        ),
        XFile.fromData(
          Uint8List.fromList([4, 5, 6]),
          name: 'video_1.mp4',
          path: '/tmp/video_1.mp4',
          mimeType: 'video/mp4',
        ),
      ];

      await tester.pumpWidget(
        buildApp(
          ExerciseMediaScreen(
            draft: const GenericExerciseRegistrationDraft(
              name: 'Trote e Galope',
              description: 'Alternar trote e galope',
              defaultDurationMinutes: 20,
            ),
            filePicker: () async => fakeFiles,
            fileSizeLoader: (_) async => 1024,
          ),
        ),
      );

      expect(find.text('Mídias auxiliares'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 6 de 7'), findsOneWidget);

      await tester.tap(find.byKey(const Key('pick-exercise-media-files')));
      await tester.pumpAndSettle();

      expect(find.text('imagem_1.png'), findsOneWidget);
      expect(find.text('video_1.mp4'), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsOneWidget);
      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);

      final continueButton = find.byKey(const Key('continue-exercise-media'));
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseConfirmationScreen), findsOneWidget);
      expect(find.text('Revise os dados'), findsOneWidget);
    },
  );

  testWidgets(
    'displays step 7 of 8 when specific draft is provided',
    (tester) async {
      const calvino = TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino');

      await tester.pumpWidget(
        buildApp(
          const ExerciseMediaScreen(
            draft: SpecificExerciseRegistrationDraft(
              horse: calvino,
              name: 'Salto Inicial',
              description: 'Descrição',
              defaultDurationMinutes: 25,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Etapa 7 de 8'), findsOneWidget);
    },
  );
}
