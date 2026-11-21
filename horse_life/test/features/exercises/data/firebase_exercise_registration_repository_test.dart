// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes unitários do FirebaseExerciseRegistrationRepository,
// cobrindo validações locais, envio de payload para genérico e específico,
// upload sequencial de mídias e tratamento de falhas.
// -----------------------------------------------------------------------------

import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/exercises/application/states/exercise_material.dart';
import 'package:horse_life/features/exercises/application/states/exercise_media.dart';
import 'package:horse_life/features/exercises/application/states/exercise_registration_draft.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/data/repositories/exercise_registration_repository.dart';
import 'package:horse_life/features/exercises/data/repositories/firebase_exercise_registration_repository.dart';
import 'package:horse_life/features/exercises/data/services/exercise_registration_remote_service.dart';

final class _FakeRemoteService implements ExerciseRegistrationRemoteService {
  Map<String, Object?>? capturedPayload;
  final List<(String, String)> preparedUploads = [];
  final List<Uint8List> sentBytes = [];
  final List<(String, String)> confirmedUploads = [];
  bool failUpload = false;
  Object? errorToThrow;

  @override
  Future<Map<String, dynamic>> registerExercise(
    Map<String, Object?> payload,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    capturedPayload = payload;
    return {
      'id': '66e1a0c2f1b2c3d4e5f6c010',
      'codigo': 23,
      'nome': payload['nome'],
    };
  }

  @override
  Future<ExerciseMediaUploadTicket> prepareMediaUpload({
    required String exerciseId,
    required String contentType,
  }) async {
    preparedUploads.add((exerciseId, contentType));
    return ExerciseMediaUploadTicket(
      path: '/fotos/exercicios/23_${preparedUploads.length}.jpg',
      url: Uri.parse('https://storage.googleapis.com/test'),
      headers: {'Content-Type': contentType},
    );
  }

  @override
  Future<void> sendMediaBytes({
    required ExerciseMediaUploadTicket ticket,
    required Uint8List bytes,
  }) async {
    if (failUpload) throw Exception('Falha de rede no upload');
    sentBytes.add(bytes);
  }

  @override
  Future<Map<String, dynamic>> confirmMedia({
    required String exerciseId,
    required String path,
  }) async {
    confirmedUploads.add((exerciseId, path));
    return {'caminho': path, 'url': 'https://storage.example.com/view'};
  }

  @override
  Future<Map<String, dynamic>> removeMedia({
    required String exerciseId,
    required String path,
  }) async {
    return {'removido': true};
  }
}

void main() {
  late _FakeRemoteService service;
  late FirebaseExerciseRegistrationRepository repository;

  setUp(() {
    service = _FakeRemoteService();
    repository = FirebaseExerciseRegistrationRepository(service: service);
  });

  group('FirebaseExerciseRegistrationRepository - Validações Locais', () {
    test('rejeita rascunho sem orientações', () async {
      const draft = GenericExerciseRegistrationDraft(
        name: 'Transições',
        description: 'Descrição válida',
        defaultDurationMinutes: 20,
        guidelines: ['   '],
      );

      expect(
        () => repository.registerExercise(draft: draft),
        throwsA(
          isA<ExerciseRegistrationFailure>().having(
            (e) => e.message,
            'message',
            contains('pelo menos uma orientação'),
          ),
        ),
      );
    });

    test('rejeita nome com menos de 3 caracteres', () async {
      const draft = GenericExerciseRegistrationDraft(
        name: 'Oi',
        description: 'Descrição válida',
        defaultDurationMinutes: 20,
        guidelines: ['Passo 1'],
      );

      expect(
        () => repository.registerExercise(draft: draft),
        throwsA(
          isA<ExerciseRegistrationFailure>().having(
            (e) => e.message,
            'message',
            contains('entre 3 e 80 caracteres'),
          ),
        ),
      );
    });

    test('rejeita duração fora do intervalo de 1 a 240 minutos', () async {
      const draft = GenericExerciseRegistrationDraft(
        name: 'Transições',
        description: 'Descrição válida',
        defaultDurationMinutes: 300,
        guidelines: ['Passo 1'],
      );

      expect(
        () => repository.registerExercise(draft: draft),
        throwsA(
          isA<ExerciseRegistrationFailure>().having(
            (e) => e.message,
            'message',
            contains('entre 1 e 240 minutos'),
          ),
        ),
      );
    });
  });

  group('FirebaseExerciseRegistrationRepository - Registro e Payloads', () {
    test('cadastra exercício genérico com payload correto', () async {
      const draft = GenericExerciseRegistrationDraft(
        name: 'Transições trote-galope',
        description: 'Alternar trote e galope em intervalos definidos.',
        defaultDurationMinutes: 20,
        guidelines: [
          'Manter contato leve com as rédeas',
          'Repetir em ambas as mãos',
        ],
        materials: [
          ExerciseMaterial(name: 'Cavalete', quantity: 2),
          ExerciseMaterial(name: 'Vara', quantity: 3),
        ],
      );

      final result = await repository.registerExercise(draft: draft);

      expect(result.id, '66e1a0c2f1b2c3d4e5f6c010');
      expect(result.code, 23);
      expect(result.name, 'Transições trote-galope');
      expect(result.hasMediaWarning, isFalse);

      final payload = service.capturedPayload!;
      expect(payload['privacidade'], 'GENERICO');
      expect(payload.containsKey('cavaloId'), isFalse);
      expect(payload['nome'], 'Transições trote-galope');
      expect(payload['duracaoPadraoMinutos'], 20);
      expect(payload['materiais'], [
        {'descricao': 'Cavalete', 'quantidade': 2},
        {'descricao': 'Vara', 'quantidade': 3},
      ]);
    });

    test('cadastra exercício específico com cavaloId vinculado', () async {
      const draft = SpecificExerciseRegistrationDraft(
        horse: TrainerLinkedHorse(
          id: '66e1a0c2f1b2c3d4e5f60050',
          name: 'Trovão',
        ),
        name: 'Salto simples',
        description: 'Salto em cavalete baixo',
        defaultDurationMinutes: 30,
        guidelines: ['Aproximação em linha reta'],
      );

      final result = await repository.registerExercise(draft: draft);

      expect(result.id, '66e1a0c2f1b2c3d4e5f6c010');
      expect(result.code, 23);

      final payload = service.capturedPayload!;
      expect(payload['privacidade'], 'ESPECIFICO');
      expect(payload['cavaloId'], '66e1a0c2f1b2c3d4e5f60050');
    });

    test('executa o upload sequencial de mídias anexadas ao rascunho', () async {
      final imageBytes = Uint8List.fromList([1, 2, 3, 4]);
      final videoBytes = Uint8List.fromList([5, 6, 7, 8]);

      final draft = GenericExerciseRegistrationDraft(
        name: 'Exercício com Mídias',
        description: 'Demonstração em foto e vídeo',
        defaultDurationMinutes: 15,
        guidelines: ['Executar com calma'],
        mediaItems: [
          ExerciseMedia(
            name: 'foto.jpg',
            path: '/path/foto.jpg',
            type: ExerciseMediaType.image,
            sizeInBytes: 4,
            readBytes: () async => imageBytes,
          ),
          ExerciseMedia(
            name: 'video.mp4',
            path: '/path/video.mp4',
            type: ExerciseMediaType.video,
            sizeInBytes: 4,
            readBytes: () async => videoBytes,
          ),
        ],
      );

      final result = await repository.registerExercise(draft: draft);

      expect(result.id, '66e1a0c2f1b2c3d4e5f6c010');
      expect(result.failedMediaCount, 0);
      expect(service.preparedUploads.length, 2);
      expect(service.preparedUploads[0].$2, 'image/jpeg');
      expect(service.preparedUploads[1].$2, 'video/mp4');
      expect(service.sentBytes, [imageBytes, videoBytes]);
      expect(service.confirmedUploads.length, 2);
    });

    test('não falha o exercício quando uma mídia falha no upload', () async {
      service.failUpload = true;

      final draft = GenericExerciseRegistrationDraft(
        name: 'Exercício Falha Mídia',
        description: 'Descrição',
        defaultDurationMinutes: 15,
        guidelines: ['Passo 1'],
        mediaItems: [
          ExerciseMedia(
            name: 'foto.jpg',
            path: '/path/foto.jpg',
            type: ExerciseMediaType.image,
            sizeInBytes: 100,
            readBytes: () async => Uint8List(10),
          ),
        ],
      );

      final result = await repository.registerExercise(draft: draft);

      expect(result.id, '66e1a0c2f1b2c3d4e5f6c010');
      expect(result.failedMediaCount, 1);
      expect(result.hasMediaWarning, isTrue);
      expect(result.warning, contains('1 mídia(s) não foram enviadas'));
    });

    test('mapeia exceções do FirebaseFunctions corretamente', () async {
      service.errorToThrow = FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'Treinador não disponível',
      );

      const draft = GenericExerciseRegistrationDraft(
        name: 'Transições',
        description: 'Descrição',
        defaultDurationMinutes: 15,
        guidelines: ['Passo 1'],
      );

      expect(
        () => repository.registerExercise(draft: draft),
        throwsA(
          isA<ExerciseRegistrationFailure>().having(
            (e) => e.message,
            'message',
            'Treinador não disponível',
          ),
        ),
      );
    });
  });
}
