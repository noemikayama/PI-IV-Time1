// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação e comentários explicativos para
// facilitar a compreensão da integração com Cloud Functions e Cloud Storage.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do adapter FirebaseExerciseDetailRepository integrado às
// Cloud Functions getExercise, updateExercise e ao fluxo de mídias auxiliares
// (createExerciseMediaUpload, confirmExerciseMedia e removeExerciseMedia).
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

import '../../application/states/exercise_material.dart';
import '../../application/states/exercise_media.dart';
import '../models/exercise_detail_data.dart';
import '../models/exercise_type.dart';
import '../models/trainer_linked_horse.dart';
import '../services/exercise_registration_remote_service.dart';
import '../services/firebase_exercise_registration_service.dart';
import 'exercise_detail_repository.dart';

/// Assinatura funcional para invocação da callable `getExercise`.
typedef GetExerciseCall = Future<Object?> Function(Map<String, Object?> payload);

/// Assinatura funcional para invocação da callable `updateExercise`.
typedef UpdateExerciseCall =
    Future<Object?> Function(Map<String, Object?> payload);

/// Adapter de produção do repositório de exercícios integrado com o Firebase.
///
/// Responsabilidades e decisões arquiteturais:
/// 1. **Comunicação regionalizada**: Todas as chamadas direcionam-se à região
///    `southamerica-east1`, conforme o contrato de infraestrutura do HorseLife.
/// 2. **Validação estrita antes do envio**: Validações de limites e tamanhos
///    (nome 3-80, descrição até 1000, 1 a 240 minutos, até 30 orientações e 30
///    materiais com quantidades entre 1 e 999) são realizadas antes de disparar
///    a requisição para poupar chamadas de rede e garantir integridade rápida.
/// 3. **Orquestração de mídias**:
///    - Exclusões de mídias ocorrem *antes* dos uploads das novas mídias para
///      liberar cotas de armazenamento por exercício (máximo 10 imagens e 3 vídeos).
///    - O upload utiliza os tickets gerados por `createExerciseMediaUpload`, envia
///      os bytes binários via HTTP PUT para a URL assinada e confirma com `confirmExerciseMedia`.
///    - Após a manipulação de arquivos, `getExercise` é reexecutado para recarregar
///      as URLs assinadas atualizadas e os metadados finais.
final class FirebaseExerciseDetailRepository implements ExerciseDetailRepository {
  FirebaseExerciseDetailRepository({
    GetExerciseCall? getExerciseCall,
    UpdateExerciseCall? updateExerciseCall,
    ExerciseRegistrationRemoteService? mediaService,
  }) : _getExerciseCall = getExerciseCall,
       _updateExerciseCall = updateExerciseCall,
       _mediaService = mediaService;

  static const _region = 'southamerica-east1';
  static const _getFunctionName = 'getExercise';
  static const _updateFunctionName = 'updateExercise';

  static final RegExp _objectIdPattern = RegExp(r'^[0-9a-fA-F]{24}$');
  static final RegExp _digitsPattern = RegExp(r'^\d+$');

  final GetExerciseCall? _getExerciseCall;
  final UpdateExerciseCall? _updateExerciseCall;
  final ExerciseRegistrationRemoteService? _mediaService;

  ExerciseRegistrationRemoteService get _resolvedMediaService =>
      _mediaService ?? FirebaseExerciseRegistrationService();

  @override
  Future<ExerciseDetailData> getExercise({String? id, String? code}) async {
    final trimmedId = id?.trim() ?? '';
    final trimmedCode = code?.trim() ?? '';

    // O backend exige id OU codigo, nunca ambos na mesma requisição.
    final Map<String, Object?> payload;
    if (_objectIdPattern.hasMatch(trimmedId)) {
      payload = {'id': trimmedId};
    } else if (_digitsPattern.hasMatch(trimmedCode)) {
      payload = {'codigo': trimmedCode};
    } else {
      throw const ExerciseDetailFailure('Identificador do exercício inválido.');
    }

    try {
      final response = await (_getExerciseCall ?? _callGetFromFirebase)(payload);
      return _parseExerciseDetail(response);
    } on ExerciseDetailFailure {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw _toFailure(
        error,
        defaultMessage: 'Não foi possível carregar os detalhes do exercício.',
      );
    } on FormatException catch (error) {
      throw ExerciseDetailFailure(error.message);
    } catch (_) {
      throw const ExerciseDetailFailure(
        'Não foi possível carregar os detalhes do exercício.',
      );
    }
  }

  @override
  Future<ExerciseUpdateResult> updateExercise({
    required ExerciseDetailData original,
    required ExerciseUpdate update,
  }) async {
    final trimmedId = original.id.trim();
    if (!_objectIdPattern.hasMatch(trimmedId)) {
      throw const ExerciseDetailFailure('Identificador do exercício inválido.');
    }

    // Valida previamente os campos no cliente para evitar erros evitáveis na callable.
    _validateUpdate(update);

    var latestExercise = original;

    // Dispara a callable de atualização apenas se houver mudanças cadastrais.
    if (update.hasFieldChanges(original)) {
      final payload = update.toUpdatePayload(original);
      try {
        final response =
            await (_updateExerciseCall ?? _callUpdateFromFirebase)(payload);
        latestExercise = _parseExerciseDetail(response);
      } on ExerciseDetailFailure {
        rethrow;
      } on FirebaseFunctionsException catch (error) {
        throw _toFailure(
          error,
          defaultMessage: 'Não foi possível atualizar o exercício.',
        );
      } on FormatException catch (error) {
        throw ExerciseDetailFailure(error.message);
      } catch (_) {
        throw const ExerciseDetailFailure(
          'Não foi possível atualizar o exercício.',
        );
      }
    }

    // Processa alterações de mídias auxiliares (exclusões e novos envios).
    if (update.hasMediaChanges) {
      final mediaService = _resolvedMediaService;
      var failedRemovals = 0;
      var failedUploads = 0;

      // 1. Remove primeiro as mídias excluídas para liberar slots antes dos novos envios.
      for (final path in update.removedMediaPaths) {
        try {
          await mediaService.removeMedia(exerciseId: trimmedId, path: path);
        } catch (_) {
          failedRemovals++;
        }
      }

      // 2. Envia as novas mídias em fluxo de 3 etapas (ticket -> PUT -> confirmação).
      for (final media in update.addedMedia) {
        try {
          final ticket = await mediaService.prepareMediaUpload(
            exerciseId: trimmedId,
            contentType: media.resolvedContentType,
          );
          final bytes = await _loadMediaBytes(media);
          await mediaService.sendMediaBytes(ticket: ticket, bytes: bytes);
          await mediaService.confirmMedia(
            exerciseId: trimmedId,
            path: ticket.path,
          );
        } catch (_) {
          failedUploads++;
        }
      }

      // 3. Recarrega via getExercise para obter URLs assinadas e caminhos atualizados.
      latestExercise = await getExercise(id: trimmedId);

      final warning = _buildMediaWarning(
        failedRemovals: failedRemovals,
        failedUploads: failedUploads,
      );
      return ExerciseUpdateResult(exercise: latestExercise, warning: warning);
    }

    return ExerciseUpdateResult(exercise: latestExercise);
  }

  /// Validações de limites e regras de negócio alinhadas à função updateExercise.
  void _validateUpdate(ExerciseUpdate update) {
    final trimmedName = update.name.trim();
    if (trimmedName.length < 3 || trimmedName.length > 80) {
      throw const ExerciseDetailFailure(
        'O nome do exercício deve ter entre 3 e 80 caracteres.',
      );
    }

    final trimmedDescription = update.description.trim();
    if (trimmedDescription.isEmpty || trimmedDescription.length > 1000) {
      throw const ExerciseDetailFailure(
        'A descrição do exercício deve ter entre 1 e 1000 caracteres.',
      );
    }

    if (update.defaultDurationMinutes < 1 ||
        update.defaultDurationMinutes > 240) {
      throw const ExerciseDetailFailure(
        'A duração padrão deve ser um número inteiro entre 1 e 240 minutos.',
      );
    }

    final cleanGuidelines = update.guidelines
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (cleanGuidelines.length > 30) {
      throw const ExerciseDetailFailure(
        'Informe no máximo 30 orientações para o exercício.',
      );
    }
    if (cleanGuidelines.any((item) => item.length > 500)) {
      throw const ExerciseDetailFailure(
        'Cada orientação deve ter no máximo 500 caracteres.',
      );
    }

    if (update.materials.length > 30) {
      throw const ExerciseDetailFailure(
        'Informe no máximo 30 materiais para o exercício.',
      );
    }
    final seenMaterials = <String>{};
    for (final material in update.materials) {
      final desc = material.name.trim();
      if (desc.isEmpty || desc.length > 100) {
        throw const ExerciseDetailFailure(
          'A descrição de cada material deve ter entre 1 e 100 caracteres.',
        );
      }
      if (material.quantity < 1 || material.quantity > 999) {
        throw const ExerciseDetailFailure(
          'A quantidade de cada material deve estar entre 1 e 999.',
        );
      }
      final key = desc.toLowerCase();
      if (!seenMaterials.add(key)) {
        throw ExerciseDetailFailure('Material repetido: $desc.');
      }
    }

    if (update.privacy == ExerciseType.specific &&
        (update.horse == null || update.horse!.id.trim().isEmpty)) {
      throw const ExerciseDetailFailure(
        'Selecione um cavalo vinculado para salvar o exercício específico.',
      );
    }
  }

  Future<Uint8List> _loadMediaBytes(ExerciseMedia media) async {
    final reader = media.readBytes;
    if (reader != null) {
      return reader();
    }
    throw const ExerciseDetailFailure(
      'Não foi possível ler os dados do arquivo de mídia.',
    );
  }

  String? _buildMediaWarning({
    required int failedRemovals,
    required int failedUploads,
  }) {
    if (failedRemovals == 0 && failedUploads == 0) return null;
    if (failedRemovals > 0 && failedUploads > 0) {
      return 'Exercício salvo, mas $failedRemovals remoção(ões) e $failedUploads envio(s) de mídia falharam.';
    }
    if (failedRemovals > 0) {
      return 'Exercício salvo, mas $failedRemovals mídia(s) não puderam ser removidas.';
    }
    return 'Exercício salvo, mas $failedUploads mídia(s) não puderam ser enviadas.';
  }

  /// Converte a resposta em formato JSON/Map vinda do Cloud Functions para [ExerciseDetailData].
  ExerciseDetailData _parseExerciseDetail(Object? response) {
    if (response is! Map) {
      throw const FormatException('Resposta dos detalhes do exercício inválida.');
    }

    final id = _extractId(response['id'] ?? response['_id']);
    if (id.isEmpty) {
      throw const FormatException('Identificador do exercício ausente.');
    }

    final name = response['nome'] ?? response['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Nome do exercício ausente.');
    }

    final code = _parseInt(response['codigo'] ?? response['code']);
    final rawDesc = response['descricao'] ?? response['description'];
    final description = rawDesc is String ? rawDesc.trim() : '';
    final duration = _parseInt(
      response['duracaoPadraoMinutos'] ?? response['duracao'],
    );

    final guidelines = <String>[];
    final rawGuidelines = response['orientacoes'];
    if (rawGuidelines is List) {
      for (final item in rawGuidelines) {
        if (item is String && item.trim().isNotEmpty) {
          guidelines.add(item.trim());
        }
      }
    }

    final materials = <ExerciseMaterial>[];
    final rawMaterials = response['materiais'];
    if (rawMaterials is List) {
      for (final item in rawMaterials) {
        if (item is! Map) continue;
        final desc = item['descricao'] ?? item['nome'];
        final qty = _parseInt(item['quantidade']);
        if (desc is String && desc.trim().isNotEmpty && qty > 0) {
          materials.add(ExerciseMaterial(name: desc.trim(), quantity: qty));
        }
      }
    }

    final privacyRaw =
        (response['privacidade'] ?? response['tipo'] ?? '').toString().toUpperCase();
    final isSpecific = privacyRaw.contains('ESPEC');
    final privacy = isSpecific ? ExerciseType.specific : ExerciseType.generic;

    TrainerLinkedHorse? horse;
    final horseRaw = response['cavalo'] ?? response['horse'];
    if (horseRaw is Map) {
      final horseId = _extractId(horseRaw['id'] ?? horseRaw['_id']);
      final horseName = horseRaw['nome'] ?? horseRaw['name'];
      if (horseId.isNotEmpty && horseName is String && horseName.trim().isNotEmpty) {
        horse = TrainerLinkedHorse(id: horseId, name: horseName.trim());
      }
    } else if (response['cavaloId'] is String &&
        (response['cavaloId'] as String).trim().isNotEmpty) {
      final horseId = (response['cavaloId'] as String).trim();
      final horseName = response['cavaloNome'] is String
          ? (response['cavaloNome'] as String).trim()
          : 'Cavalo vinculado';
      horse = TrainerLinkedHorse(id: horseId, name: horseName);
    }

    final trainerId = _extractId(
      response['treinadorId'] ?? response['trainerId'] ?? response['criadorId'],
    );
    final trainerName = response['treinadorNome'] ?? response['trainerName'];

    final images = <ExerciseDetailMedia>[];
    final rawImages = response['imagens'] ?? response['images'];
    if (rawImages is List) {
      for (final item in rawImages) {
        final parsed = _parseDetailMedia(item, fallback: ExerciseMediaType.image);
        if (parsed != null) images.add(parsed);
      }
    }

    final videos = <ExerciseDetailMedia>[];
    final rawVideos = response['videos'];
    if (rawVideos is List) {
      for (final item in rawVideos) {
        final parsed = _parseDetailMedia(item, fallback: ExerciseMediaType.video);
        if (parsed != null) videos.add(parsed);
      }
    }

    final permissions = response['permissoes'] is Map
        ? response['permissoes'] as Map
        : (response['permissions'] is Map ? response['permissions'] as Map : null);

    final canEdit = response['canEdit'] == true ||
        response['podeEditar'] == true ||
        response['isOwner'] == true ||
        permissions?['editar'] == true ||
        permissions?['edit'] == true;

    final createdAt = _parseDateTime(response['criadoEm'] ?? response['createdAt']);
    final updatedAt =
        _parseDateTime(response['atualizadoEm'] ?? response['updatedAt']);

    return ExerciseDetailData(
      id: id,
      code: code,
      name: name.trim(),
      description: description,
      defaultDurationMinutes: duration,
      guidelines: List.unmodifiable(guidelines),
      materials: List.unmodifiable(materials),
      privacy: privacy,
      horse: horse,
      trainerId: trainerId.isNotEmpty ? trainerId : null,
      trainerName: trainerName is String ? trainerName.trim() : null,
      images: List.unmodifiable(images),
      videos: List.unmodifiable(videos),
      canEdit: canEdit,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ExerciseDetailMedia? _parseDetailMedia(
    Object? raw, {
    required ExerciseMediaType fallback,
  }) {
    if (raw is! Map) return null;
    final path = (raw['caminho'] ?? raw['path'] ?? raw['storagePath'] ?? '')
        .toString()
        .trim();
    final url = (raw['url'] ?? raw['downloadUrl'] ?? '').toString().trim();
    if (path.isEmpty || url.isEmpty) return null;

    final inferred = ExerciseDetailMedia.inferMediaType(
      path: path,
      url: url,
      fallback: fallback,
    );

    return ExerciseDetailMedia(path: path, url: url, type: inferred);
  }

  String _extractId(Object? raw) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is Map && raw[r'$oid'] is String) {
      return (raw[r'$oid'] as String).trim();
    }
    return raw.toString().trim();
  }

  int _parseInt(Object? raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) {
      return int.tryParse(raw.trim()) ?? 0;
    }
    return 0;
  }

  DateTime? _parseDateTime(Object? raw) {
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is Map && raw[r'$date'] is String) {
      return DateTime.tryParse(raw[r'$date'] as String);
    }
    return null;
  }

  Future<Object?> _callGetFromFirebase(Map<String, Object?> payload) async {
    final callable = FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_getFunctionName);
    final result = await callable.call<Object?>(payload);
    return result.data;
  }

  Future<Object?> _callUpdateFromFirebase(Map<String, Object?> payload) async {
    final callable = FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_updateFunctionName);
    final result = await callable.call<Object?>(payload);
    return result.data;
  }

  ExerciseDetailFailure _toFailure(
    FirebaseFunctionsException error, {
    required String defaultMessage,
  }) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').trim();

    if (code == 'not-found' || message.contains('não encontrado')) {
      return const ExerciseDetailFailure('Exercício não encontrado.');
    }
    if (code == 'permission-denied' || message.contains('permissão')) {
      return const ExerciseDetailFailure(
        'Você não tem permissão para alterar este exercício.',
      );
    }
    if (code == 'already-exists' || message.contains('já cadastrado')) {
      return const ExerciseDetailFailure('Já existe um exercício com este nome.');
    }
    if (message.isNotEmpty) {
      return ExerciseDetailFailure(message);
    }
    return ExerciseDetailFailure(defaultMessage);
  }
}
