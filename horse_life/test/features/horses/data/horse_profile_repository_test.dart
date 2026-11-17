// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação e cobertura dos fluxos de exclusão, timeout,
// vínculos e processamento das imagens do perfil.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura das modalidades usadas na edição do cavalo.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do mapeamento de getHorse e da serialização de
// updateHorse.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/horses/data/models/horse_profile_data.dart';
import 'package:horse_life/features/horses/data/repositories/horse_profile_repository.dart';
import 'package:horse_life/features/horses/data/services/horse_registration_remote_service.dart';

void main() {
  test('mapeia o contrato completo de getHorseProfile', () {
    final horse = mapHorseProfile(_horseJson());

    expect(horse.id, 'horse-1');
    expect(horse.name, 'Trovão');
    expect(horse.age.years, 10);
    expect(horse.images.single.url, 'https://example.test/horse.jpg');
    expect(horse.modality?.name, 'Salto');
    expect(horse.owner.name, 'Ana');
    expect(horse.trainers.single.name, 'Bruno');
    expect(horse.currentPlan?.title, 'Plano A');
    expect(horse.evaluations.single.trainer.name, 'Bruno');
    expect(horse.canEdit, isTrue);
  });

  test('serializa apenas nomes de campos aceitos por updateHorse', () {
    final update = HorseProfileUpdate(
      name: 'Trovão II',
      birthDate: DateTime(2016, 4, 10),
      breed: 'BH',
      coat: 'Tordilho',
      sex: 'MACHO',
      modalityId: null,
      shouldUpdateModality: true,
      physicalLimitations: const HorseProfileListChanges(
        added: ['Sensibilidade'],
      ),
      healthNotes: const HorseProfileListChanges(added: ['Vacinas em dia']),
      injuries: HorseProfileListChanges(
        added: [
          HorseInjuryRecord(
            date: DateTime(2025, 3, 12),
            description: 'Distensão leve',
            prescription: 'Repouso',
          ),
        ],
      ),
    );

    expect(update.toJson('horse-1'), {
      'id': 'horse-1',
      'nome': 'Trovão II',
      'dataNascimento': '2016-04-10',
      'raca': 'BH',
      'pelagem': 'Tordilho',
      'sexo': 'MACHO',
      'modalidadeId': null,
      'limitacoesFisicas': {
        'adicionar': ['Sensibilidade'],
        'remover': <String>[],
      },
      'observacoesSaude': {
        'adicionar': ['Vacinas em dia'],
        'remover': <String>[],
      },
      'historicoLesoes': {
        'adicionar': [
          {
            'data': '2025-03-12',
            'descricao': 'Distensão leve',
            'prescricao': 'Repouso',
          },
        ],
        'remover': <Map<String, String>>[],
      },
    });
  });

  test('interrompe atualização quando o backend não responde', () {
    final repository = FirebaseHorseProfileRepository(
      updateHorse: (_) => Completer<Object?>().future,
      requestTimeout: const Duration(milliseconds: 20),
    );

    expect(
      repository.updateHorse(
        'horse-1',
        const HorseProfileUpdate(name: 'Trovão II'),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('envia nova lesão como inclusão no contrato de updateHorse', () async {
    Map<String, Object?>? receivedPayload;
    final previousInjury = HorseInjuryRecord(
      date: DateTime(2025, 3, 12),
      description: 'Distensão leve',
      prescription: 'Repouso',
    );
    final newInjury = HorseInjuryRecord(
      date: DateTime(2026, 11, 14),
      description: 'Edema no boleto',
      prescription: 'Gelo e repouso',
    );
    final repository = FirebaseHorseProfileRepository(
      updateHorse: (payload) async {
        receivedPayload = payload;
        return _horseJson();
      },
    );

    await repository.updateHorse(
      'horse-1',
      HorseProfileUpdate(
        injuries: horseProfileListChanges(
          [previousInjury],
          [previousInjury, newInjury],
        ),
      ),
    );

    expect(receivedPayload, {
      'id': 'horse-1',
      'historicoLesoes': {
        'adicionar': [
          {
            'data': '2026-11-14',
            'descricao': 'Edema no boleto',
            'prescricao': 'Gelo e repouso',
          },
        ],
        'remover': <Map<String, String>>[],
      },
    });
  });

  test('carrega as modalidades disponíveis para edição', () async {
    final repository = FirebaseHorseProfileRepository(
      getModalities: (_) async => [
        {'id': 'mod-1', 'nome': 'Salto'},
        {'id': 'mod-2', 'nome': 'Adestramento'},
      ],
    );

    final modalities = await repository.getModalities();

    expect(modalities.map((item) => item.id), ['mod-1', 'mod-2']);
    expect(modalities.map((item) => item.name), ['Salto', 'Adestramento']);
  });

  test('interrompe modalidades quando o backend não responde', () {
    final repository = FirebaseHorseProfileRepository(
      getModalities: (_) => Completer<Object?>().future,
      requestTimeout: const Duration(milliseconds: 20),
    );

    expect(repository.getModalities(), throwsA(isA<TimeoutException>()));
  });

  test('interrompe consulta do perfil quando o backend não responde', () {
    final repository = FirebaseHorseProfileRepository(
      getHorse: (_) => Completer<Object?>().future,
      requestTimeout: const Duration(milliseconds: 20),
    );

    expect(repository.getHorse('horse-1'), throwsA(isA<TimeoutException>()));
  });

  test(
    'envia o id para deleteHorse e exige a confirmação do backend',
    () async {
      Map<String, Object?>? receivedPayload;
      final repository = FirebaseHorseProfileRepository(
        deleteHorse: (payload) async {
          receivedPayload = payload;
          return {'excluido': true};
        },
      );

      await repository.deleteHorse('horse-1');

      expect(receivedPayload, {'id': 'horse-1'});
    },
  );

  test('interrompe exclusão quando o backend não responde', () {
    final repository = FirebaseHorseProfileRepository(
      deleteHorse: (_) => Completer<Object?>().future,
      requestTimeout: const Duration(milliseconds: 20),
    );

    expect(repository.deleteHorse('horse-1'), throwsA(isA<TimeoutException>()));
  });

  test('envia novos vínculos para updateHorseLinks', () async {
    Map<String, Object?>? updatePayload;
    final repository = FirebaseHorseProfileRepository(
      updateHorseLinks: (payload) async {
        updatePayload = payload;
        return _horseJson();
      },
    );

    await repository.updateRelationships(
      'horse-1',
      removeAthlete: false,
      removeTrainer: false,
      athleteEmail: ' atleta@example.com ',
      trainerEmail: ' treinador@example.com ',
    );

    expect(updatePayload, {
      'id': 'horse-1',
      'emailAtleta': 'atleta@example.com',
      'emailTreinador': 'treinador@example.com',
    });
  });

  test('interrompe atualização de vínculos quando o backend não responde', () {
    final repository = FirebaseHorseProfileRepository(
      updateHorseLinks: (_) => Completer<Object?>().future,
      requestTimeout: const Duration(milliseconds: 20),
    );

    expect(
      repository.updateRelationships(
        'horse-1',
        removeAthlete: false,
        removeTrainer: false,
        athleteEmail: 'atleta@example.com',
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('remove cada tipo de vínculo por removeHorseLink', () async {
    final removePayloads = <Map<String, Object?>>[];
    final repository = FirebaseHorseProfileRepository(
      removeHorseLink: (payload) async {
        removePayloads.add(payload);
        return _horseJson();
      },
    );

    await repository.updateRelationships(
      'horse-1',
      removeAthlete: true,
      removeTrainer: true,
    );

    expect(removePayloads, [
      {'id': 'horse-1', 'vinculo': 'ATLETA'},
      {'id': 'horse-1', 'vinculo': 'TREINADOR'},
    ]);
  });

  test('substitui o treinador sem removê-lo antes', () async {
    var removals = 0;
    Map<String, Object?>? updatePayload;
    final repository = FirebaseHorseProfileRepository(
      removeHorseLink: (payload) async {
        removals++;
        return _horseJson();
      },
      updateHorseLinks: (payload) async {
        updatePayload = payload;
        return _horseJson();
      },
    );

    await repository.updateRelationships(
      'horse-1',
      removeAthlete: false,
      removeTrainer: true,
      trainerEmail: 'novo@example.com',
    );

    expect(removals, 0);
    expect(updatePayload, {
      'id': 'horse-1',
      'emailTreinador': 'novo@example.com',
    });
  });

  test('envia várias fotos pela URL criada para cada imagem', () async {
    final imageService = _RecordingImageService();
    var horseReloads = 0;
    final repository = FirebaseHorseProfileRepository(
      imageService: imageService,
      getHorse: (_) async {
        horseReloads++;
        return _horseJson();
      },
    );

    final result = await repository.addHorseImages(
      'horse-1',
      images: [
        HorseProfileImageUpload(
          fileName: 'frente.jpg',
          bytes: Uint8List.fromList([0xFF, 0xD8]),
        ),
        HorseProfileImageUpload(
          fileName: 'lateral.png',
          bytes: Uint8List.fromList([0x89, 0x50]),
        ),
      ],
    );

    expect(imageService.preparedContentTypes, ['image/jpeg', 'image/png']);
    expect(imageService.sentPaths, [
      '/fotos/cavalos/horse-1/imagem_1.jpg',
      '/fotos/cavalos/horse-1/imagem_2.png',
    ]);
    expect(imageService.confirmedPaths, imageService.sentPaths);
    expect(result.uploaded, 2);
    expect(result.failed, 0);
    expect(horseReloads, 1);
  });

  test('não esconde o erro quando nenhuma imagem é enviada', () async {
    final imageService = _RecordingImageService(
      sendError: const FormatException('Storage recusou o upload.'),
    );
    final repository = FirebaseHorseProfileRepository(
      imageService: imageService,
      getHorse: (_) async => _horseJson(),
    );

    await expectLater(
      repository.addHorseImages(
        'horse-1',
        images: [
          HorseProfileImageUpload(
            fileName: 'frente.jpg',
            bytes: Uint8List.fromList([0xFF, 0xD8]),
          ),
        ],
      ),
      throwsA(
        isA<HorseImageUploadFailure>()
            .having(
              (error) => error.stage,
              'stage',
              HorseImageUploadStage.upload,
            )
            .having(
              (error) => error.cause,
              'cause',
              isA<FormatException>().having(
                (cause) => cause.message,
                'message',
                'Storage recusou o upload.',
              ),
            ),
      ),
    );
  });

  test('interrompe preparação de imagem quando o backend não responde', () {
    final imageService = _RecordingImageService(
      prepareCompletion: Completer<HorseImageUploadTicket>(),
    );
    final repository = FirebaseHorseProfileRepository(
      imageService: imageService,
      requestTimeout: const Duration(milliseconds: 20),
    );

    expect(
      repository.addHorseImages(
        'horse-1',
        images: [
          HorseProfileImageUpload(
            fileName: 'frente.jpg',
            bytes: Uint8List.fromList([0xFF, 0xD8]),
          ),
        ],
      ),
      throwsA(
        isA<HorseImageUploadFailure>()
            .having(
              (error) => error.stage,
              'stage',
              HorseImageUploadStage.prepare,
            )
            .having((error) => error.cause, 'cause', isA<TimeoutException>()),
      ),
    );
  });
}

class _RecordingImageService implements HorseRegistrationRemoteService {
  _RecordingImageService({this.sendError, this.prepareCompletion});

  final Object? sendError;
  final Completer<HorseImageUploadTicket>? prepareCompletion;
  final List<String> preparedContentTypes = [];
  final List<String> sentPaths = [];
  final List<String> confirmedPaths = [];

  @override
  Future<HorseImageUploadTicket> prepareImage(
    String horseId,
    String contentType,
  ) async {
    final pending = prepareCompletion;
    if (pending != null) return pending.future;
    preparedContentTypes.add(contentType);
    final index = preparedContentTypes.length;
    final extension = contentType == 'image/png' ? 'png' : 'jpg';
    return HorseImageUploadTicket(
      path: '/fotos/cavalos/$horseId/imagem_$index.$extension',
      url: Uri.parse('https://storage.example.test/upload/$index'),
      headers: {'Content-Type': contentType},
    );
  }

  @override
  Future<void> sendImage(HorseImageUploadTicket ticket, Uint8List bytes) async {
    if (sendError case final error?) throw error;
    sentPaths.add(ticket.path);
  }

  @override
  Future<void> confirmImage(String horseId, String path) async {
    confirmedPaths.add(path);
  }

  @override
  Future<List<Map<String, dynamic>>> getModalities() async => const [];

  @override
  Future<Map<String, dynamic>> registerHorse(
    Map<String, Object?> payload,
  ) async => const {};

  @override
  Future<void> removeImage(String horseId, String path) async {}
}

Map<String, dynamic> _horseJson() => {
  'id': 'horse-1',
  'codigo': '123123456789012',
  'nome': 'Trovão',
  'dataNascimento': '2016-04-10',
  'idade': {'anos': 10, 'meses': 7},
  'raca': 'Brasileiro de Hipismo',
  'pelagem': 'Tordilho',
  'sexo': 'MACHO',
  'imagens': [
    {'caminho': '/horse.jpg', 'url': 'https://example.test/horse.jpg'},
  ],
  'modalidade': {'id': 'mod-1', 'codigo': 1, 'nome': 'Salto'},
  'limitacoesFisicas': ['Sensibilidade'],
  'observacoesSaude': ['Vacinas em dia'],
  'historicoLesoes': [
    {
      'data': '2025-03-12',
      'descricao': 'Distensão leve',
      'prescricao': 'Repouso',
    },
  ],
  'proprietario': {'id': 'owner-1', 'codigo': 1, 'nome': 'Ana'},
  'atleta': null,
  'treinador': {'id': 'trainer-1', 'codigo': 2, 'nome': 'Bruno'},
  'planoAtual': {'id': 'plan-1', 'codigo': 3, 'titulo': 'Plano A'},
  'avaliacoes': [
    {
      'id': 'evaluation-1',
      'codigo': 4,
      'data': '2026-10-01',
      'treinador': {'id': 'trainer-1', 'codigo': 2, 'nome': 'Bruno'},
    },
  ],
  'responsabilidades': ['PROPRIETARIO'],
  'situacaoCadastral': 'ATIVO',
  'criadoEm': '2026-01-01T00:00:00.000Z',
  'atualizadoEm': '2026-11-01T00:00:00.000Z',
};
