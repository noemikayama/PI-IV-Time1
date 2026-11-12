// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Inclusão de teste validando o bloqueio de submissão do exercício
// quando a lista de orientações fica vazia na tela de revisão.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da tela de revisão final do cadastro de
// exercícios, cobrindo a diferença entre fluxo genérico (etapa 7 de 7, sem
// cavalo) e específico (etapa 8 de 8, com "Cavalo selecionado"), edição inline
// e remoção de itens.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/application/states/exercise_material.dart';
import 'package:horse_life/features/exercises/application/states/exercise_media.dart';
import 'package:horse_life/features/exercises/application/states/exercise_registration_draft.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_confirmation_screen.dart';

void main() {
  Widget buildApp(ExerciseConfirmationScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets(
    'renders generic review on step 7 of 7 without selected horse section and allows inline edits and item removal',
    (tester) async {
      ExerciseRegistrationDraft? submittedDraft;

      await tester.pumpWidget(
        buildApp(
          ExerciseConfirmationScreen(
            draft: const GenericExerciseRegistrationDraft(
              name: 'Trote e Galope',
              description: 'Alternar trote e galope em intervalos definidos',
              defaultDurationMinutes: 20,
              guidelines: [
                'Manter contato leve com as rédeas',
                'Aumentar o ritmo progressivamente',
              ],
              materials: [
                ExerciseMaterial(name: 'Cavalete', quantity: 3),
                ExerciseMaterial(name: 'Vara', quantity: 2),
              ],
              mediaItems: [
                ExerciseMedia(
                  name: 'imagem_1.png',
                  path: '/tmp/imagem_1.png',
                  type: ExerciseMediaType.image,
                  sizeInBytes: 512,
                ),
                ExerciseMedia(
                  name: 'video_1.mp4',
                  path: '/tmp/video_1.mp4',
                  type: ExerciseMediaType.video,
                  sizeInBytes: 2048,
                ),
              ],
            ),
            onSubmitted: (draft) => submittedDraft = draft,
          ),
        ),
      );

      expect(find.text('Revise os dados'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 7 de 7'), findsOneWidget);
      expect(find.text('Cavalo selecionado'), findsNothing);
      expect(
        find.byKey(const Key('exercise-review-selected-horse')),
        findsNothing,
      );

      expect(find.text('(3) Cavalete'), findsOneWidget);
      expect(find.text('imagem_1.png'), findsOneWidget);
      expect(find.text('video_1.mp4'), findsOneWidget);

      // Edita o nome inline
      await tester.tap(find.byTooltip('Editar Nome'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('exercise-review-name')),
        'Trote e Galope Avançado',
      );
      await tester.pump();

      // Remove o segundo material
      final removeMaterialButton = find.byKey(
        const ValueKey('remove-exercise-review-material-1'),
      );
      await tester.ensureVisible(removeMaterialButton);
      await tester.tap(removeMaterialButton);
      await tester.pump();

      expect(find.text('(2) Vara'), findsNothing);

      final submitButton = find.byKey(
        const Key('submit-exercise-registration'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(submittedDraft, isNotNull);
      expect(submittedDraft!.name, 'Trote e Galope Avançado');
      expect(submittedDraft!.materials.length, 1);
      expect(submittedDraft!.materials.first.name, 'Cavalete');
    },
  );

  testWidgets(
    'renders specific review on step 8 of 8 displaying Cavalo selecionado section',
    (tester) async {
      const calvino = TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino');

      await tester.pumpWidget(
        buildApp(
          const ExerciseConfirmationScreen(
            draft: SpecificExerciseRegistrationDraft(
              horse: calvino,
              name: 'Transição com Cavalete',
              description: 'Alternar trote e galope em intervalos definidos',
              defaultDurationMinutes: 25,
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Etapa 8 de 8'), findsOneWidget);
      expect(find.text('Cavalo selecionado'), findsOneWidget);
      expect(
        find.byKey(const Key('exercise-review-selected-horse')),
        findsOneWidget,
      );
      expect(find.text('Calvino'), findsOneWidget);
    },
  );

  testWidgets(
    'restricts submission and displays error when all guidelines are removed',
    (tester) async {
      var submitted = false;

      await tester.pumpWidget(
        buildApp(
          ExerciseConfirmationScreen(
            draft: const GenericExerciseRegistrationDraft(
              name: 'Trote e Galope',
              description: 'Descrição',
              defaultDurationMinutes: 15,
              guidelines: ['Manter contato leve com as rédeas'],
            ),
            onSubmitted: (_) => submitted = true,
          ),
        ),
      );

      expect(find.text('Manter contato leve com as rédeas'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('remove-exercise-review-guideline-0')),
      );
      await tester.pump();

      expect(find.text('Manter contato leve com as rédeas'), findsNothing);
      expect(find.text('Nenhuma orientação adicionada.'), findsOneWidget);

      final submitButton = find.byKey(
        const Key('submit-exercise-registration'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(submitted, isFalse);
      expect(
        find.text('Adicione pelo menos uma orientação para cadastrar o exercício.'),
        findsOneWidget,
      );
    },
  );
}
