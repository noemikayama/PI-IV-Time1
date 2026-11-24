// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação e comentários explicativos para
// facilitar a leitura e manutenção dos testes de widget de detalhes e edição de exercícios.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes de widget das telas ExerciseDetailScreen e
// ExerciseEditScreen cobrindo seções recolhíveis, exibição condicional por
// permissão de edição, estados vazios, alternância imagem/vídeo no carrossel,
// transição Genérico/Específico com validação de cavalo vinculado e uso dos
// modais do cadastro para orientações, materiais e mídias auxiliares.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/exercises/application/states/exercise_material.dart';
import 'package:horse_life/features/exercises/application/states/exercise_media.dart';
import 'package:horse_life/features/exercises/data/models/exercise_detail_data.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/data/repositories/exercise_detail_repository.dart';
import 'package:horse_life/features/exercises/data/repositories/trainer_linked_horse_repository.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_detail_screen.dart';
import 'package:horse_life/features/exercises/presentation/screens/exercise_edit_screen.dart';

class _SpyExerciseDetailRepository extends LocalExerciseDetailRepository {
  _SpyExerciseDetailRepository({super.initialExercise});

  int updateCalls = 0;
  ExerciseUpdate? lastUpdate;

  @override
  Future<ExerciseUpdateResult> updateExercise({
    required ExerciseDetailData original,
    required ExerciseUpdate update,
  }) async {
    updateCalls++;
    lastUpdate = update;
    return super.updateExercise(original: original, update: update);
  }
}

class _StubHorseRepository implements TrainerLinkedHorseRepository {
  const _StubHorseRepository(this.horses);

  final List<TrainerLinkedHorse> horses;

  @override
  Future<List<TrainerLinkedHorse>> fetchLinkedHorses() async => horses;
}

ExerciseDetailData _sampleExercise({
  ExerciseType privacy = ExerciseType.generic,
  TrainerLinkedHorse? horse,
  bool canEdit = true,
  List<ExerciseDetailMedia> images = const [],
  List<ExerciseDetailMedia> videos = const [],
  List<String> guidelines = const ['Manter contato leve com as rédeas'],
  List<ExerciseMaterial> materials = const [
    ExerciseMaterial(name: 'Cavalete', quantity: 3),
    ExerciseMaterial(name: 'Vara', quantity: 2),
  ],
}) {
  return ExerciseDetailData(
    id: '66e1a0c2f1b2c3d4e5f6c010',
    code: 23,
    name: 'Transições trote-galope',
    description: 'Alternar trote e galope em intervalos definidos.',
    defaultDurationMinutes: 20,
    guidelines: guidelines,
    materials: materials,
    privacy: privacy,
    horse: horse,
    trainerId: 'trainer-1',
    trainerName: 'Carlos Mendes',
    images: images,
    videos: videos,
    canEdit: canEdit,
  );
}

void main() {
  Widget buildApp(Widget screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets(
    'exibe visualização completa do exercício genérico com botão Editar e seções recolhíveis',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _SpyExerciseDetailRepository(
        initialExercise: _sampleExercise(
          images: const [
            ExerciseDetailMedia(
              path: '/fotos/exercicios/23_1.png',
              url: 'https://cdn.example.com/23_1.png',
              type: ExerciseMediaType.image,
            ),
          ],
          videos: const [
            ExerciseDetailMedia(
              path: '/videos/exercicios/23_1.mp4',
              url: 'https://cdn.example.com/23_1.mp4',
              type: ExerciseMediaType.video,
            ),
          ],
        ),
      );

      await tester.pumpWidget(
        buildApp(
          ExerciseDetailScreen(
            exerciseId: '66e1a0c2f1b2c3d4e5f6c010',
            currentUserId: 'trainer-1',
            isTrainer: true,
            repository: repo,
            imageBuilder: (_, media) => Container(
              key: Key('stub-image-${media.fileName}'),
              color: Colors.teal,
              child: Center(child: Text('IMG:${media.fileName}')),
            ),
            videoPlayerBuilder: (_, media) => Container(
              key: Key('stub-video-${media.fileName}'),
              color: Colors.black,
              child: Center(child: Text('VID:${media.fileName}')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit-exercise-button')), findsOneWidget);
      expect(find.textContaining('Privacidade: genérico'), findsOneWidget);
      expect(find.textContaining('Cavalo selecionado:'), findsNothing);
      expect(find.text('Manter contato leve com as rédeas'), findsOneWidget);
      expect(find.textContaining('(3) Cavalete'), findsOneWidget);

      // Primeiro item do carrossel é a imagem e o segundo dot abre o vídeo.
      expect(find.byKey(const Key('stub-image-23_1.png')), findsOneWidget);
      await tester.tap(find.byKey(const Key('exercise-media-dot-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stub-video-23_1.mp4')), findsOneWidget);

      // Seções colapsáveis recolhem e expandem ao toque.
      await tester.tap(find.text('Dados do exercício'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Privacidade: genérico'), findsNothing);
    },
  );

  testWidgets(
    'exibe Cavalo selecionado para exercício específico e oculta Editar exercício quando sem permissão',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildApp(
          ExerciseDetailScreen(
            exerciseId: '66e1a0c2f1b2c3d4e5f6c010',
            currentUserId: 'guardian-1',
            isTrainer: false,
            repository: _SpyExerciseDetailRepository(
              initialExercise: _sampleExercise(
                privacy: ExerciseType.specific,
                horse: const TrainerLinkedHorse(id: 'horse-1', name: 'Calvino'),
                canEdit: false,
                guidelines: const [],
                materials: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit-exercise-button')), findsNothing);
      expect(find.textContaining('Privacidade: específico'), findsOneWidget);
      expect(
        find.textContaining('Cavalo selecionado: Calvino'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('exercise-detail-media-empty')),
        findsOneWidget,
      );
      expect(find.text('Nenhuma mídia adicionada'), findsOneWidget);
      expect(
        find.byKey(const Key('exercise-detail-materials-empty')),
        findsOneWidget,
      );
      expect(find.text('Nenhum'), findsOneWidget);
    },
  );

  testWidgets(
    'impede salvar mudança para específico quando não houver cavalos vinculados',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      ExerciseUpdate? savedUpdate;
      await tester.pumpWidget(
        buildApp(
          ExerciseEditScreen(
            exercise: _sampleExercise(),
            horseRepository: const _StubHorseRepository([]),
            onSaved: (update) => savedUpdate = update,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('exercise-edit-privacy-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Específico').last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('exercise-edit-no-horses-message')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('save-exercise-edit-button')),
      );
      await tester.tap(find.byKey(const Key('save-exercise-edit-button')));
      await tester.pumpAndSettle();

      expect(savedUpdate, isNull);
      expect(
        find.textContaining('pelo menos um cavalo vinculado'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'edita exercício completo: troca genérico para específico com cavalo, usa modais do cadastro e salva alterações',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = _SpyExerciseDetailRepository(
        initialExercise: _sampleExercise(
          images: const [
            ExerciseDetailMedia(
              path: '/fotos/exercicios/23_1.png',
              url: 'https://cdn.example.com/23_1.png',
              type: ExerciseMediaType.image,
            ),
          ],
        ),
      );
      final fakeHorses = const [
        TrainerLinkedHorse(id: 'horse-1', name: 'Trovão'),
        TrainerLinkedHorse(id: 'horse-2', name: 'Calvino'),
      ];

      await tester.pumpWidget(
        buildApp(
          ExerciseDetailScreen(
            exerciseId: '66e1a0c2f1b2c3d4e5f6c010',
            currentUserId: 'trainer-1',
            isTrainer: true,
            repository: repo,
            horseRepository: _StubHorseRepository(fakeHorses),
            filePicker: () async => [
              XFile.fromData(
                Uint8List.fromList(const [1, 2, 3, 4]),
                name: 'video_guia.mp4',
                path: 'video_guia.mp4',
              ),
            ],
            fileSizeLoader: (_) async => 1024,
            imageBuilder: (_, media) => Text('IMG:${media.fileName}'),
            videoPlayerBuilder: (_, media) => Text('VID:${media.fileName}'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit-exercise-button')));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseEditScreen), findsOneWidget);

      // Alterna de Genérico para Específico e escolhe o segundo cavalo.
      await tester.tap(find.byKey(const Key('exercise-edit-privacy-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Específico').last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('exercise-edit-horse-dropdown')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('exercise-edit-horse-dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calvino').last);
      await tester.pumpAndSettle();

      // Edita nome inline.
      await tester.tap(find.byTooltip('Editar Nome'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('exercise-edit-name-field')),
        'Transições ajustadas',
      );
      await tester.pump();

      // Adiciona orientação pelo modal do cadastro.
      await tester.ensureVisible(
        find.byKey(const Key('exercise-edit-add-guideline-button')),
      );
      await tester.tap(
        find.byKey(const Key('exercise-edit-add-guideline-button')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('exercise-guideline-input')),
        'Aumentar o ritmo progressivamente',
      );
      await tester.tap(find.byKey(const Key('save-exercise-guideline')));
      await tester.pumpAndSettle();

      // Adiciona material pelo modal do cadastro.
      await tester.ensureVisible(
        find.byKey(const Key('exercise-edit-add-material-button')),
      );
      await tester.tap(
        find.byKey(const Key('exercise-edit-add-material-button')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('exercise-material-name-input')),
        'Rio',
      );
      await tester.tap(find.byKey(const Key('save-exercise-material')));
      await tester.pumpAndSettle();

      // Adiciona mídia pelo seletor de arquivos.
      await tester.ensureVisible(
        find.byKey(const Key('exercise-edit-add-media-button')),
      );
      await tester.tap(
        find.byKey(const Key('exercise-edit-add-media-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('video_guia.mp4'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('save-exercise-edit-button')),
      );
      await tester.tap(find.byKey(const Key('save-exercise-edit-button')));
      await tester.pumpAndSettle();

      expect(repo.updateCalls, 1);
      expect(repo.lastUpdate?.name, 'Transições ajustadas');
      expect(repo.lastUpdate?.privacy, ExerciseType.specific);
      expect(repo.lastUpdate?.horse?.name, 'Calvino');
      expect(
        repo.lastUpdate?.guidelines,
        contains('Aumentar o ritmo progressivamente'),
      );
      expect(
        repo.lastUpdate?.materials.map((m) => m.name),
        contains('Rio'),
      );
      expect(
        repo.lastUpdate?.addedMedia.map((m) => m.name),
        contains('video_guia.mp4'),
      );
      expect(find.byType(ExerciseDetailScreen), findsOneWidget);
      expect(find.text('Transições ajustadas'), findsWidgets);
      expect(
        find.textContaining('Cavalo selecionado: Calvino'),
        findsOneWidget,
      );
    },
  );
}
