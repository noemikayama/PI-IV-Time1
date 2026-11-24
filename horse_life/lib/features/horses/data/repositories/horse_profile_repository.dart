// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Mapeamento do período e treino diário do plano ativo, além da ação
// de execução calculada pelo backend para o perfil consultado.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos contratos, mapeamentos e fluxos de perfil,
// exclusão, vínculos e imagens; inclusão de timeout nas fronteiras remotas.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão do carregamento de modalidades e das operações de imagem
// para a edição integrada à Function updateHorse e às callables de Storage.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração do perfil com getHorse e updateHorse, sem mudanças
// no backend.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

import '../models/horse_profile_data.dart';
import '../services/firebase_horse_registration_service.dart';
import '../services/horse_registration_remote_service.dart';

// --- Contratos injetáveis e resultados do fluxo de imagens ------------------
// Estes tipos permitem testar a camada sem inicializar Firebase ou Storage.

typedef HorseProfileCall = Future<Object?> Function(Map<String, Object?> data);

/// Imagem já lida pela apresentação e pronta para transferência.
class HorseProfileImageUpload {
  const HorseProfileImageUpload({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

/// Resultado consolidado de um lote, inclusive quando parte dele falha.
class HorseProfileImageUploadResult {
  const HorseProfileImageUploadResult({
    required this.horse,
    required this.uploaded,
    required this.failed,
  });

  final HorseProfileData horse;
  final int uploaded;
  final int failed;
}

/// Etapa remota em que uma imagem deixou de ser processada.
enum HorseImageUploadStage { prepare, upload, confirm }

/// Mantém a etapa e a causa original de uma falha no fluxo de imagens.
class HorseImageUploadFailure implements Exception {
  const HorseImageUploadFailure({required this.stage, required this.cause});

  final HorseImageUploadStage stage;
  final Object cause;

  String get userMessage {
    if (cause is FirebaseFunctionsException) {
      final error = cause as FirebaseFunctionsException;
      return switch (error.code) {
        'unauthenticated' => 'Entre novamente na sua conta para enviar fotos.',
        'permission-denied' =>
          'O backend recusou o envio. Apenas o proprietário pode alterar as fotos do cavalo.',
        'not-found' || 'invalid-argument' =>
          error.message ?? 'O backend recusou os dados da imagem.',
        'unavailable' ||
        'deadline-exceeded' => 'O backend está indisponível. Tente novamente.',
        _ => error.message ?? _stageMessage,
      };
    }
    if (cause is HorseImageStorageException) {
      final error = cause as HorseImageStorageException;
      return 'O Storage recusou a imagem (HTTP ${error.statusCode}). Tente novamente.';
    }
    if (cause is FormatException) {
      return (cause as FormatException).message;
    }
    return _stageMessage;
  }

  String get _stageMessage => switch (stage) {
    HorseImageUploadStage.prepare =>
      'Não foi possível preparar o envio da imagem no backend.',
    HorseImageUploadStage.upload =>
      'Não foi possível enviar a imagem ao Storage.',
    HorseImageUploadStage.confirm =>
      'A imagem foi enviada, mas o backend não conseguiu confirmá-la.',
  };

  @override
  String toString() => 'HorseImageUploadFailure(stage: $stage, cause: $cause)';
}

/// Fronteira de consulta e edição do perfil do cavalo.
abstract interface class HorseProfileRepository {
  Future<HorseProfileData> getHorse(String id);
  Future<List<HorseProfileModality>> getModalities();
  Future<HorseProfileData> updateHorse(String id, HorseProfileUpdate update);
  Future<void> deleteHorse(String id);
  Future<HorseProfileData> updateRelationships(
    String id, {
    required bool removeAthlete,
    required bool removeTrainer,
    String? athleteEmail,
    String? trainerEmail,
  });
  Future<HorseProfileImageUploadResult> addHorseImages(
    String id, {
    required List<HorseProfileImageUpload> images,
  });
  Future<HorseProfileData> removeHorseImage(String id, String path);
}

/// Implementação das callables regionais já publicadas pelo backend.
class FirebaseHorseProfileRepository implements HorseProfileRepository {
  const FirebaseHorseProfileRepository({
    HorseProfileCall? getHorse,
    HorseProfileCall? getModalities,
    HorseProfileCall? updateHorse,
    HorseProfileCall? deleteHorse,
    HorseProfileCall? updateHorseLinks,
    HorseProfileCall? removeHorseLink,
    HorseRegistrationRemoteService? imageService,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _getHorse = getHorse,
       _getModalities = getModalities,
       _updateHorse = updateHorse,
       _deleteHorse = deleteHorse,
       _updateHorseLinks = updateHorseLinks,
       _removeHorseLink = removeHorseLink,
       _imageService = imageService;

  final HorseProfileCall? _getHorse;
  final HorseProfileCall? _getModalities;
  final HorseProfileCall? _updateHorse;
  final HorseProfileCall? _deleteHorse;
  final HorseProfileCall? _updateHorseLinks;
  final HorseProfileCall? _removeHorseLink;
  final HorseRegistrationRemoteService? _imageService;
  final Duration requestTimeout;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  HorseRegistrationRemoteService get _images =>
      _imageService ?? FirebaseHorseRegistrationService();

  // --- Consulta, edição e exclusão ------------------------------------------
  // Cada fronteira remota possui tempo máximo para que a interface possa sair
  // do carregamento e oferecer nova tentativa quando o backend não responder.

  @override
  Future<HorseProfileData> getHorse(String id) async {
    final response = await (_getHorse ?? _callGetHorse)({
      'id': id,
    }).timeout(requestTimeout);
    return mapHorseProfile(_responseMap(response));
  }

  @override
  Future<List<HorseProfileModality>> getModalities() async {
    final result = await (_getModalities ?? _callGetModalities)(
      const {},
    ).timeout(requestTimeout);
    if (result is! List) {
      throw const FormatException('Lista de modalidades inválida.');
    }
    return result
        .map((item) {
          final json = _map(item);
          return HorseProfileModality(
            id: _requiredText(json['id'], 'id da modalidade'),
            name: _requiredText(json['nome'], 'nome da modalidade'),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<HorseProfileData> updateHorse(
    String id,
    HorseProfileUpdate update,
  ) async {
    final response = await (_updateHorse ?? _callUpdateHorse)(
      update.toJson(id),
    ).timeout(requestTimeout);
    return mapHorseProfile(_responseMap(response));
  }

  @override
  Future<void> deleteHorse(String id) async {
    final response = await (_deleteHorse ?? _callDeleteHorse)({
      'id': id,
    }).timeout(requestTimeout);
    final result = _responseMap(response);
    if (result['excluido'] != true) {
      throw const FormatException(
        'O servidor não confirmou a exclusão do cavalo.',
      );
    }
  }

  // --- Sincronização dos vínculos -------------------------------------------
  // Remoções e substituições usam as callables específicas e retornam sempre
  // o retrato atualizado do cavalo para manter a tela consistente.

  @override
  Future<HorseProfileData> updateRelationships(
    String id, {
    required bool removeAthlete,
    required bool removeTrainer,
    String? athleteEmail,
    String? trainerEmail,
  }) async {
    final normalizedAthleteEmail = athleteEmail?.trim();
    final normalizedTrainerEmail = trainerEmail?.trim();
    final isReplacingAthlete = normalizedAthleteEmail?.isNotEmpty ?? false;
    final isReplacingTrainer = normalizedTrainerEmail?.isNotEmpty ?? false;
    HorseProfileData? updated;

    if (removeAthlete && !isReplacingAthlete) {
      final response = await (_removeHorseLink ?? _callRemoveHorseLink)({
        'id': id,
        'vinculo': 'ATLETA',
      }).timeout(requestTimeout);
      updated = mapHorseProfile(_responseMap(response));
    }
    if (removeTrainer && !isReplacingTrainer) {
      final response = await (_removeHorseLink ?? _callRemoveHorseLink)({
        'id': id,
        'vinculo': 'TREINADOR',
      }).timeout(requestTimeout);
      updated = mapHorseProfile(_responseMap(response));
    }
    if (isReplacingAthlete || isReplacingTrainer) {
      final response = await (_updateHorseLinks ?? _callUpdateHorseLinks)({
        'id': id,
        if (isReplacingAthlete) 'emailAtleta': normalizedAthleteEmail,
        if (isReplacingTrainer) 'emailTreinador': normalizedTrainerEmail,
      }).timeout(requestTimeout);
      updated = mapHorseProfile(_responseMap(response));
    }
    return updated ?? getHorse(id);
  }

  // --- Pipeline de imagens --------------------------------------------------
  // Cada arquivo percorre preparação, PUT no Storage e confirmação. Falhas são
  // contabilizadas por item; se nenhuma imagem subir, a primeira causa retorna.

  @override
  Future<HorseProfileImageUploadResult> addHorseImages(
    String id, {
    required List<HorseProfileImageUpload> images,
  }) async {
    var uploaded = 0;
    var failed = 0;
    HorseImageUploadFailure? firstFailure;
    StackTrace? firstFailureStackTrace;
    for (final image in images) {
      try {
        final contentType = image.fileName.toLowerCase().endsWith('.png')
            ? 'image/png'
            : 'image/jpeg';
        final HorseImageUploadTicket ticket;
        try {
          ticket = await _images
              .prepareImage(id, contentType)
              .timeout(requestTimeout);
        } catch (error) {
          throw HorseImageUploadFailure(
            stage: HorseImageUploadStage.prepare,
            cause: error,
          );
        }
        try {
          await _images.sendImage(ticket, image.bytes).timeout(requestTimeout);
        } catch (error) {
          throw HorseImageUploadFailure(
            stage: HorseImageUploadStage.upload,
            cause: error,
          );
        }
        try {
          await _images.confirmImage(id, ticket.path).timeout(requestTimeout);
        } catch (error) {
          throw HorseImageUploadFailure(
            stage: HorseImageUploadStage.confirm,
            cause: error,
          );
        }
        uploaded++;
      } on HorseImageUploadFailure catch (error, stackTrace) {
        firstFailure ??= error;
        firstFailureStackTrace ??= stackTrace;
        failed++;
      }
    }
    if (uploaded == 0 && firstFailure != null) {
      Error.throwWithStackTrace(firstFailure, firstFailureStackTrace!);
    }
    return HorseProfileImageUploadResult(
      horse: await getHorse(id),
      uploaded: uploaded,
      failed: failed,
    );
  }

  @override
  Future<HorseProfileData> removeHorseImage(String id, String path) async {
    await _images.removeImage(id, path).timeout(requestTimeout);
    return getHorse(id);
  }

  // --- Adaptadores das Cloud Functions -------------------------------------
  // Centralizam os nomes das callables para que o restante do repositório
  // trabalhe apenas com contratos Dart e possa receber dublês nos testes.

  Future<Object?> _callGetHorse(Map<String, Object?> data) async {
    final result = await _functions
        .httpsCallable('getHorseProfile')
        .call<Object?>(data);
    return result.data;
  }

  Future<Object?> _callGetModalities(Map<String, Object?> data) async {
    final result = await _functions
        .httpsCallable('getModalities')
        .call<Object?>();
    return result.data;
  }

  Future<Object?> _callUpdateHorse(Map<String, Object?> data) async {
    final result = await _functions
        .httpsCallable('updateHorse')
        .call<Object?>(data);
    return result.data;
  }

  Future<Object?> _callDeleteHorse(Map<String, Object?> data) async {
    final result = await _functions
        .httpsCallable('deleteHorse')
        .call<Object?>(data);
    return result.data;
  }

  Future<Object?> _callUpdateHorseLinks(Map<String, Object?> data) async {
    final result = await _functions
        .httpsCallable('updateHorseLinks')
        .call<Object?>(data);
    return result.data;
  }

  Future<Object?> _callRemoveHorseLink(Map<String, Object?> data) async {
    final result = await _functions
        .httpsCallable('removeHorseLink')
        .call<Object?>(data);
    return result.data;
  }
}

// --- Conversão do contrato remoto -------------------------------------------

/// Converte o contrato remoto em um modelo sem dependência do SDK Firebase.
HorseProfileData mapHorseProfile(Map<String, dynamic> json) {
  final age = _map(json['idade']);
  return HorseProfileData(
    id: _requiredText(json['id'], 'id'),
    // getHorseProfile omite o microchip para quem não é proprietário.
    microchip: _text(json['codigo']),
    name: _requiredText(json['nome'], 'nome'),
    birthDate: _requiredDate(json['dataNascimento'], 'dataNascimento'),
    age: HorseProfileAge(
      years: _integer(age['anos']),
      months: _integer(age['meses']),
    ),
    breed: _requiredText(json['raca'], 'raca'),
    coat: _requiredText(json['pelagem'], 'pelagem'),
    sex: _requiredText(json['sexo'], 'sexo'),
    images: _list(json['imagens'])
        .map(_map)
        .map(
          (item) => HorseProfileImage(
            path: _text(item['caminho']),
            url: _text(item['url']),
          ),
        )
        .where((item) => item.url.isNotEmpty)
        .toList(growable: false),
    modality: _optionalModality(json['modalidade']),
    physicalLimitations: _textList(json['limitacoesFisicas']),
    healthNotes: _textList(json['observacoesSaude']),
    injuries: _list(json['historicoLesoes'])
        .map(_map)
        .map(
          (item) => HorseInjuryRecord(
            date: _requiredDate(item['data'], 'data da lesão'),
            description: _requiredText(item['descricao'], 'descrição'),
            prescription: _nullableText(item['prescricao']),
          ),
        )
        .toList(growable: false),
    owner: _person(json['proprietario']),
    athlete: json['atleta'] == null ? null : _person(json['atleta']),
    trainers: _horseTrainers(json),
    currentPlan: _optionalPlan(json['planoAtual']),
    evaluations: _list(json['avaliacoes'])
        .map(_map)
        .map(
          (item) => HorseProfileEvaluation(
            id: _requiredText(item['id'], 'id da avaliação'),
            date: _requiredDate(item['data'], 'data da avaliação'),
            trainer: _person(item['treinador']),
          ),
        )
        .toList(growable: false),
    responsibilities: _textList(json['responsabilidades']),
    trainingAction: _trainingAction(_map(json['permissoes'])['acaoTreino']),
  );
}

List<HorseProfilePerson> _horseTrainers(Map<String, dynamic> json) {
  final legacyTrainers = _list(json['treinadores']);
  if (legacyTrainers.isNotEmpty) {
    return legacyTrainers.map(_person).toList(growable: false);
  }
  final trainer = json['treinador'];
  return trainer == null ? const [] : [_person(trainer)];
}

// --- Leitores defensivos do JSON --------------------------------------------
// Normalizam mapas, listas, textos, datas e inteiros antes de criar o agregado.

Map<String, dynamic> _responseMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Resposta inválida da Cloud Function.');
}

HorseProfilePerson _person(dynamic value) {
  final json = _map(value);
  return HorseProfilePerson(
    id: _requiredText(json['id'], 'id do vínculo'),
    name: _requiredText(json['nome'], 'nome do vínculo'),
  );
}

HorseProfileModality? _optionalModality(dynamic value) {
  if (value == null) return null;
  final json = _map(value);
  return HorseProfileModality(
    id: _requiredText(json['id'], 'id da modalidade'),
    name: _requiredText(json['nome'], 'nome da modalidade'),
  );
}

// Converte o plano e preserva a ausência legítima de período ou treino diário.
HorseProfilePlan? _optionalPlan(dynamic value) {
  if (value == null) return null;
  final json = _map(value);
  final today = _map(json['treinoDoDia']);
  final training = _map(today['treino']);
  return HorseProfilePlan(
    id: _requiredText(json['id'], 'id do plano'),
    title: _requiredText(json['titulo'], 'título do plano'),
    startDate: DateTime.tryParse(_text(json['dataInicio'])),
    endDate: DateTime.tryParse(_text(json['dataFim'])),
    todayTraining: training.isEmpty
        ? null
        : HorseProfileDayTraining(
            recordId: _requiredText(
              training['registroId'],
              'registro do treino do dia',
            ),
            name: _requiredText(
              training['nomeTreino'],
              'nome do treino do dia',
            ),
            planName: _requiredText(training['nomePlano'], 'nome do plano'),
            durationMinutes: _integer(training['duracaoMinutos']),
            personRole: _text(_map(training['pessoa'])['papel']),
            personName: _text(_map(training['pessoa'])['nome']),
            status: _requiredText(
              training['status'],
              'status do treino do dia',
            ),
          ),
  );
}

// Traduz somente as ações públicas do contrato; valores novos ficam seguros.
HorseProfileTrainingAction _trainingAction(dynamic value) =>
    switch (_text(value)) {
      'INICIAR' => HorseProfileTrainingAction.start,
      'VER' => HorseProfileTrainingAction.view,
      _ => HorseProfileTrainingAction.none,
    };

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
List<dynamic> _list(dynamic value) => value is List ? value : const [];
String _text(dynamic value) => value is String ? value.trim() : '';
String? _nullableText(dynamic value) {
  final result = _text(value);
  return result.isEmpty ? null : result;
}

String _requiredText(dynamic value, String field) {
  final result = _text(value);
  if (result.isEmpty) throw FormatException('Campo $field inválido.');
  return result;
}

DateTime _requiredDate(dynamic value, String field) {
  final result = DateTime.tryParse(_text(value));
  if (result == null) throw FormatException('Campo $field inválido.');
  return result;
}

int _integer(dynamic value) => value is num ? value.toInt() : 0;
List<String> _textList(dynamic value) => _list(
  value,
).map(_text).where((item) => item.isNotEmpty).toList(growable: false);
