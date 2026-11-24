// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação e comentários explicativos para
// facilitar a leitura e manutenção dos testes unitários do repositório de exercícios.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes unitários de FirebaseExerciseDetailRepository
// cobrindo consulta por id ou código, mapeamento genérico/específico e mídias,
// envio parcial de campos editados, transição de privacidade/cavalo,
// remoção/envio ordenado de mídias auxiliares e tratamento de erros.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/exercises/application/states/exercise_material.dart';
import 'package:horse_life/features/exercises/application/states/exercise_media.dart';
import 'package:horse_life/features/exercises/data/models/exercise_detail_data.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/data/repositories/exercise_detail_repository.dart';
import 'package:horse_life/features/exercises/data/repositories/firebase_exercise_detail_repository.dart';
import 'package:horse_life/features/exercises/data/services/exercise_registration_remote_service.dart';

class _FakeMediaRemoteService implements ExerciseRegistrationRemoteService {
  final List<String> operations = [];
  bool failNextUpload = false;

  @override
  Future<Map<String, dynamic>> registerExercise(Map<String, Object?> payload) {
    throw UnimplementedError();
  }

  @override
  Future<ExerciseMediaUploadTicket> prepareMediaUpload({
    required String exerciseId,
    required String contentType,
  }) async {
    operations.add('prepare:$exerciseId:$contentType');
    if (failNextUpload) {
      failNextUpload = false;
      throw FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'Limite atingido.',
      );
    }
    return ExerciseMediaUploadTicket(
      path: '/fotos/exercicios/23_2.png',
      url: Uri.parse('https://upload.example.com/23_2.png'),
      headers: {'Content-Type': contentType},
    );
  }

  @override
  Future<void> sendMediaBytes({
    required ExerciseMediaUploadTicket ticket,
    required Uint8List bytes,
  }) async {
    operations.add('put:${ticket.path}:${bytes.length}');
  }

  @override
  Future<Map<String, dynamic>> confirmMedia({
    required String exerciseId,
    required String path,
  }) async {
    operations.add('confirm:$exerciseId:$path');
    return {'caminho': path, 'url': 'https://cdn.example.com$path'};
  }

  @override
  Future<Map<String, dynamic>> removeMedia({
    required String exerciseId,
    required String path,
  }) async {
    operations.add('remove:$exerciseId:$path');
    return {'removido': true};
  }
}

Map<String, Object?> _exerciseJson({
  String id = '66e1a0c2f1b2c3d4e5f6c010',
  int codigo = 23,
  String nome = 'Transições trote-galope',
  String descricao = 'Alternar trote e galope em intervalos definidos.',
  int duracao = 20,
  String privacidade = 'GENERICO',
  Map<String, Object?>? cavalo,
  List<Map<String, Object?>> imagens = const [],
  List<Map<String, Object?>> videos = const [],
  bool canEdit = true,
}) {
  return {
    'id': id,
    'codigo': codigo,
    'nome': nome,
    'descricao': descricao,
    'orientacoes': ['Manter contato leve com as rédeas'],
    'duracaoPadraoMinutos': duracao,
    'materiais': [
      {'descricao': 'Cavalete', 'quantidade': 2},
    ],
    'privacidade': privacidade,
    // ignore: use_null_aware_elements
    if (cavalo != null) 'cavalo': cavalo,
    'treinador': {'id': 'trainer-1', 'codigo': 92, 'nome': 'Carlos Mendes'},
    'imagens': imagens,
    'videos': videos,
    'permissoes': {'editar': canEdit},
    'criadoEm': '2026-11-10T14:30:00.000Z',
    'atualizadoEm': '2026-11-20T09:12:00.000Z',
  };
}

void main() {
  test('consulta exercício por id enviando apenas id e infere tipo de mídia', () async {
    Map<String, Object?>? capturedPayload;
    final repo = FirebaseExerciseDetailRepository(
      getExerciseCall: (payload) async {
        capturedPayload = payload;
        return _exerciseJson(
          privacidade: 'ESPECIFICO',
          cavalo: {
            'id': '66e1a0c2f1b2c3d4e5f60050',
            'codigo': '123456',
            'nome': 'Trovão',
          },
          imagens: [
            {
              'caminho': '/fotos/exercicios/23_1.jpg',
              'url': 'https://cdn.example.com/23_1.jpg?token=abc',
            },
          ],
          videos: [
            {
              'caminho': '/videos/exercicios/23_1.mp4',
              'url': 'https://cdn.example.com/23_1.mp4?token=xyz',
            },
          ],
        );
      },
    );

    final detail = await repo.getExercise(
      id: '66e1a0c2f1b2c3d4e5f6c010',
      code: '23',
    );

    expect(capturedPayload, {'id': '66e1a0c2f1b2c3d4e5f6c010'});
    expect(capturedPayload!.containsKey('codigo'), isFalse);
    expect(detail.privacy, ExerciseType.specific);
    expect(detail.horse?.id, '66e1a0c2f1b2c3d4e5f60050');
    expect(detail.horse?.name, 'Trovão');
    expect(detail.images.single.type, ExerciseMediaType.image);
    expect(detail.images.single.fileName, '23_1.jpg');
    expect(detail.videos.single.type, ExerciseMediaType.video);
    expect(detail.canEdit, isTrue);
  });

  test('consulta exercício por código quando id não for ObjectId válido', () async {
    Map<String, Object?>? capturedPayload;
    final repo = FirebaseExerciseDetailRepository(
      getExerciseCall: (payload) async {
        capturedPayload = payload;
        return _exerciseJson(canEdit: false);
      },
    );

    final detail = await repo.getExercise(id: null, code: ' 23 ');

    expect(capturedPayload, {'codigo': '23'});
    expect(detail.code, 23);
    expect(detail.canEdit, isFalse);
  });

  test('envia apenas campos alterados na transição genérico para específico', () async {
    Map<String, Object?>? updatePayload;
    final original = ExerciseDetailData(
      id: '66e1a0c2f1b2c3d4e5f6c010',
      code: 23,
      name: 'Transições trote-galope',
      description: 'Alternar trote e galope.',
      defaultDurationMinutes: 20,
      guidelines: const ['Manter contato leve'],
      materials: const [ExerciseMaterial(name: 'Cavalete', quantity: 2)],
      privacy: ExerciseType.generic,
      images: const [],
      videos: const [],
      canEdit: true,
    );

    final repo = FirebaseExerciseDetailRepository(
      updateExerciseCall: (payload) async {
        updatePayload = payload;
        return _exerciseJson(
          nome: 'Transições curtas',
          privacidade: 'ESPECIFICO',
          cavalo: {
            'id': '66e1a0c2f1b2c3d4e5f60051',
            'nome': 'Calvino',
          },
        );
      },
    );

    final result = await repo.updateExercise(
      original: original,
      update: ExerciseUpdate(
        name: 'Transições curtas',
        description: 'Alternar trote e galope.',
        defaultDurationMinutes: 20,
        guidelines: const ['Manter contato leve'],
        materials: const [ExerciseMaterial(name: 'Cavalete', quantity: 2)],
        privacy: ExerciseType.specific,
        horse: const TrainerLinkedHorse(
          id: '66e1a0c2f1b2c3d4e5f60051',
          name: 'Calvino',
        ),
      ),
    );

    expect(updatePayload, {
      'id': '66e1a0c2f1b2c3d4e5f6c010',
      'nome': 'Transições curtas',
      'privacidade': 'ESPECIFICO',
      'cavaloId': '66e1a0c2f1b2c3d4e5f60051',
    });
    expect(result.exercise.privacy, ExerciseType.specific);
    expect(result.exercise.horse?.name, 'Calvino');
  });

  test('transição específico para genérico omite cavaloId e bloqueia específico sem cavalo', () async {
    Map<String, Object?>? updatePayload;
    final specificOriginal = ExerciseDetailData(
      id: '66e1a0c2f1b2c3d4e5f6c010',
      code: 23,
      name: 'Treino',
      description: 'Desc',
      defaultDurationMinutes: 15,
      guidelines: const [],
      materials: const [],
      privacy: ExerciseType.specific,
      horse: const TrainerLinkedHorse(
        id: '66e1a0c2f1b2c3d4e5f60051',
        name: 'Calvino',
      ),
      images: const [],
      videos: const [],
      canEdit: true,
    );

    final repo = FirebaseExerciseDetailRepository(
      updateExerciseCall: (payload) async {
        updatePayload = payload;
        return _exerciseJson(
          nome: 'Treino',
          descricao: 'Desc',
          duracao: 15,
          privacidade: 'GENERICO',
        );
      },
    );

    await repo.updateExercise(
      original: specificOriginal,
      update: const ExerciseUpdate(
        name: 'Treino',
        description: 'Desc',
        defaultDurationMinutes: 15,
        guidelines: [],
        materials: [],
        privacy: ExerciseType.generic,
      ),
    );

    expect(updatePayload, {
      'id': '66e1a0c2f1b2c3d4e5f6c010',
      'privacidade': 'GENERICO',
    });
    expect(updatePayload!.containsKey('cavaloId'), isFalse);

    await expectLater(
      () => repo.updateExercise(
        original: specificOriginal,
        update: const ExerciseUpdate(
          name: 'Treino',
          description: 'Desc',
          defaultDurationMinutes: 15,
          guidelines: [],
          materials: [],
          privacy: ExerciseType.specific,
          horse: null,
        ),
      ),
      throwsA(isA<ExerciseDetailFailure>()),
    );
  });

  test('edição exclusiva de mídias remove antes de enviar e recarrega getExercise', () async {
    var updateCalled = false;
    var getCalled = false;
    final mediaService = _FakeMediaRemoteService();

    final original = ExerciseDetailData(
      id: '66e1a0c2f1b2c3d4e5f6c010',
      code: 23,
      name: 'Transições trote-galope',
      description: 'Alternar trote e galope.',
      defaultDurationMinutes: 20,
      guidelines: const ['Manter contato leve'],
      materials: const [ExerciseMaterial(name: 'Cavalete', quantity: 2)],
      privacy: ExerciseType.generic,
      images: const [
        ExerciseDetailMedia(
          path: '/fotos/exercicios/23_1.jpg',
          url: 'https://cdn.example.com/23_1.jpg',
          type: ExerciseMediaType.image,
        ),
      ],
      videos: const [],
      canEdit: true,
    );

    final repo = FirebaseExerciseDetailRepository(
      updateExerciseCall: (_) async {
        updateCalled = true;
        return _exerciseJson();
      },
      getExerciseCall: (_) async {
        getCalled = true;
        return _exerciseJson(
          imagens: [
            {
              'caminho': '/fotos/exercicios/23_2.png',
              'url': 'https://cdn.example.com/23_2.png',
            },
          ],
        );
      },
      mediaService: mediaService,
    );

    final result = await repo.updateExercise(
      original: original,
      update: ExerciseUpdate(
        name: 'Transições trote-galope',
        description: 'Alternar trote e galope.',
        defaultDurationMinutes: 20,
        guidelines: const ['Manter contato leve'],
        materials: const [ExerciseMaterial(name: 'Cavalete', quantity: 2)],
        privacy: ExerciseType.generic,
        removedMediaPaths: const ['/fotos/exercicios/23_1.jpg'],
        addedMedia: [
          ExerciseMedia(
            name: 'nova.png',
            path: 'nova.png',
            type: ExerciseMediaType.image,
            sizeInBytes: 4,
            readBytes: () async => Uint8List.fromList([1, 2, 3, 4]),
          ),
        ],
      ),
    );

    expect(updateCalled, isFalse);
    expect(getCalled, isTrue);
    expect(mediaService.operations, [
      'remove:66e1a0c2f1b2c3d4e5f6c010:/fotos/exercicios/23_1.jpg',
      'prepare:66e1a0c2f1b2c3d4e5f6c010:image/png',
      'put:/fotos/exercicios/23_2.png:4',
      'confirm:66e1a0c2f1b2c3d4e5f6c010:/fotos/exercicios/23_2.png',
    ]);
    expect(result.hasWarning, isFalse);
    expect(result.exercise.images.single.path, '/fotos/exercicios/23_2.png');
  });

  test('retorna aviso quando upload de mídia falha parcialmente', () async {
    final mediaService = _FakeMediaRemoteService()..failNextUpload = true;
    final original = ExerciseDetailData(
      id: '66e1a0c2f1b2c3d4e5f6c010',
      code: 23,
      name: 'Transições trote-galope',
      description: 'Alternar trote e galope.',
      defaultDurationMinutes: 20,
      guidelines: const [],
      materials: const [],
      privacy: ExerciseType.generic,
      images: const [],
      videos: const [],
      canEdit: true,
    );

    final repo = FirebaseExerciseDetailRepository(
      getExerciseCall: (_) async => _exerciseJson(),
      mediaService: mediaService,
    );

    final result = await repo.updateExercise(
      original: original,
      update: ExerciseUpdate(
        name: 'Transições trote-galope',
        description: 'Alternar trote e galope.',
        defaultDurationMinutes: 20,
        guidelines: const [],
        materials: const [],
        privacy: ExerciseType.generic,
        addedMedia: [
          ExerciseMedia(
            name: 'foto.jpg',
            path: 'foto.jpg',
            type: ExerciseMediaType.image,
            sizeInBytes: 3,
            readBytes: () async => Uint8List.fromList([1, 2, 3]),
          ),
        ],
      ),
    );

    expect(result.hasWarning, isTrue);
    expect(result.warning, contains('não puderam ser enviadas'));
  });
}
