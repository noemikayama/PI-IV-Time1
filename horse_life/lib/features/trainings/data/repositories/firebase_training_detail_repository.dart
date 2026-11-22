// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Suporte à resolução por código do fallbackTraining caso o
// identificador primário seja não numérico (ex: ID de registro da agenda).
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do adapter FirebaseTrainingDetailRepository integrado às
// Cloud Functions getTrainingDetails, updateTraining e getExercise na região
// southamerica-east1.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import '../../../exercises/data/models/exercise_type.dart';
import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../../../training_plans/data/models/training_plan_gallery_item.dart';
import '../mocks/mock_training_detail.dart';
import '../models/training_detail_data.dart';
import '../models/training_exercise_item.dart';
import 'training_detail_repository.dart';

// Seams das callables para permitir testes unitários de serialização e erros.
typedef TrainingDetailCall =
    Future<Object?> Function(Map<String, Object?> payload);
typedef TrainingUpdateCall =
    Future<Object?> Function(Map<String, Object?> payload);
typedef ExerciseDetailByIdCall =
    Future<Object?> Function(Map<String, Object?> payload);

/// Implementa a visualização e edição de treinamentos via Cloud Functions
/// `getTrainingDetails`, `updateTraining` e `getExercise` em `southamerica-east1`.
final class FirebaseTrainingDetailRepository implements TrainingDetailRepository {
  const FirebaseTrainingDetailRepository({
    TrainingDetailCall? getTrainingDetails,
    TrainingUpdateCall? updateTraining,
    ExerciseDetailByIdCall? getExercise,
  }) : _getTrainingDetails = getTrainingDetails,
       _updateTraining = updateTraining,
       _getExercise = getExercise;

  static const _region = 'southamerica-east1';
  static const _detailFunctionName = 'getTrainingDetails';
  static const _updateFunctionName = 'updateTraining';
  static const _exerciseFunctionName = 'getExercise';

  final TrainingDetailCall? _getTrainingDetails;
  final TrainingUpdateCall? _updateTraining;
  final ExerciseDetailByIdCall? _getExercise;

  @override
  Future<TrainingDetailData> getTrainingDetails(
    String trainingCode, {
    TrainingPlanGalleryItem? fallbackTraining,
  }) async {
    final trimmedCode = trainingCode.trim();
    if (trimmedCode.isEmpty) {
      throw const TrainingDetailFailure('Código do treinamento inválido.');
    }

    // Códigos não numéricos representam mocks/identificadores locais ou de registros.
    if (!RegExp(r'^\d+$').hasMatch(trimmedCode)) {
      if (fallbackTraining != null && fallbackTraining.code > 0) {
        return getTrainingDetails(
          fallbackTraining.code.toString(),
          fallbackTraining: fallbackTraining,
        );
      }
      return MockTrainingDetail.buildDefault(
        trainingCode: trimmedCode,
        initialTraining: fallbackTraining,
      );
    }

    try {
      final response = await (_getTrainingDetails ?? _callDetailFromFirebase)({
        'codigo': trimmedCode,
      });
      return _parseTrainingDetail(response, fallbackCode: trimmedCode);
    } on FirebaseFunctionsException catch (error) {
      if (_getTrainingDetails == null &&
          (error.code == 'unimplemented' ||
              error.code == 'internal' ||
              error.code == 'unavailable')) {
        return MockTrainingDetail.buildDefault(
          trainingCode: trimmedCode,
          initialTraining: fallbackTraining,
        );
      }
      throw _toFailure(
        error,
        defaultMessage: 'Não foi possível carregar os detalhes do treinamento.',
      );
    } on FormatException catch (error) {
      throw TrainingDetailFailure(error.message);
    } catch (_) {
      if (_getTrainingDetails == null) {
        return MockTrainingDetail.buildDefault(
          trainingCode: trimmedCode,
          initialTraining: fallbackTraining,
        );
      }
      throw const TrainingDetailFailure(
        'Não foi possível carregar os detalhes do treinamento.',
      );
    }
  }

  @override
  Future<TrainingDetailData> updateTraining(
    String trainingCode,
    TrainingUpdate update,
  ) async {
    final trimmedCode = trainingCode.trim();
    if (trimmedCode.isEmpty || !RegExp(r'^\d+$').hasMatch(trimmedCode)) {
      throw const TrainingDetailFailure('Código do treinamento inválido.');
    }

    final trimmedTitle = update.title.trim();
    if (trimmedTitle.length < 3 || trimmedTitle.length > 80) {
      throw const TrainingDetailFailure(
        'O título deve ter entre 3 e 80 caracteres.',
      );
    }

    final trimmedDescription = update.description.trim();
    if (trimmedDescription.length > 1000) {
      throw const TrainingDetailFailure(
        'A descrição deve ter no máximo 1000 caracteres.',
      );
    }

    final duration = update.estimatedDurationMinutes;
    if (duration < 1 || duration > 480) {
      throw const TrainingDetailFailure(
        'A duração estimada deve ser um número inteiro entre 1 e 480 minutos.',
      );
    }

    if (update.exercises.isEmpty || update.exercises.length > 50) {
      throw const TrainingDetailFailure(
        'Selecione entre 1 e 50 exercícios para o treinamento.',
      );
    }

    final totalExercisesDuration = update.exercises.fold<int>(
      0,
      (total, exercise) => total + exercise.estimatedDurationMinutes,
    );
    if (duration < totalExercisesDuration) {
      throw TrainingDetailFailure(
        'A duração estimada não pode ser menor que a soma dos exercícios ($totalExercisesDuration min).',
      );
    }

    final cleanGuidelines = update.guidelines
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (cleanGuidelines.isEmpty) {
      throw const TrainingDetailFailure(
        'Adicione pelo menos uma orientação para atualizar o treinamento.',
      );
    }
    if (cleanGuidelines.length > 30) {
      throw const TrainingDetailFailure(
        'Informe no máximo 30 orientações para o treinamento.',
      );
    }
    if (cleanGuidelines.any((item) => item.length > 500)) {
      throw const TrainingDetailFailure(
        'Cada orientação deve ter no máximo 500 caracteres.',
      );
    }

    try {
      final resolvedCodes = await _resolveExerciseCodes(update.exercises);
      final payload = update.toJson(
        trimmedCode,
        resolvedExerciseCodes: resolvedCodes,
      );
      final response = await (_updateTraining ?? _callUpdateFromFirebase)(
        payload,
      );
      return _parseTrainingDetail(
        response,
        fallbackCode: trimmedCode,
        fallbackExercises: update.exercises,
      );
    } on TrainingDetailFailure {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw _toFailure(
        error,
        defaultMessage: 'Não foi possível atualizar o treinamento.',
      );
    } on FormatException catch (error) {
      throw TrainingDetailFailure(error.message);
    }
  }

  Future<List<String>> _resolveExerciseCodes(
    List<TrainingExerciseItem> exercises,
  ) async {
    final cachedById = <String, String>{};
    final codes = <String>[];

    for (final exercise in exercises) {
      if (exercise.code != null && exercise.code! > 0) {
        codes.add(exercise.code.toString());
        continue;
      }

      final trimmedId = exercise.id.trim();
      if (RegExp(r'^\d+$').hasMatch(trimmedId)) {
        codes.add(trimmedId);
        continue;
      }

      if (cachedById.containsKey(trimmedId)) {
        codes.add(cachedById[trimmedId]!);
        continue;
      }

      if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(trimmedId)) {
        final response = await (_getExercise ?? _callGetExerciseFromFirebase)({
          'id': trimmedId,
        });
        if (response is! Map) {
          throw TrainingDetailFailure(
            'Não foi possível consultar o código do exercício "${exercise.name}".',
          );
        }
        final resolved = _parseInt(response['codigo'] ?? response['code']);
        if (resolved < 1) {
          throw TrainingDetailFailure(
            'Código inválido retornado para o exercício "${exercise.name}".',
          );
        }
        final resolvedStr = resolved.toString();
        cachedById[trimmedId] = resolvedStr;
        codes.add(resolvedStr);
        continue;
      }

      throw TrainingDetailFailure(
        'Não foi possível identificar o código do exercício "${exercise.name}".',
      );
    }

    return List.unmodifiable(codes);
  }

  TrainingDetailData _parseTrainingDetail(
    Object? response, {
    required String fallbackCode,
    List<TrainingExerciseItem>? fallbackExercises,
  }) {
    if (response is! Map) {
      throw const FormatException(
        'Resposta dos detalhes do treinamento inválida.',
      );
    }

    final rawCode = response['codigo'] ?? response['code'];
    final code = _extractCode(rawCode, fallback: fallbackCode);
    final rawTitle = response['titulo'] ?? response['title'];
    if (rawTitle is! String || rawTitle.trim().isEmpty) {
      throw const FormatException('Título do treinamento ausente na resposta.');
    }

    final rawDescription = response['descricao'] ?? response['description'];
    final description =
        rawDescription is String ? rawDescription.trim() : '';

    final estimatedDuration = _parseInt(
      response['duracaoEstimada'] ?? response['duracaoEstimadaMinutos'],
    );

    final rawExercises = response['exercicios'];
    final exercises = _parseExercises(
      rawExercises,
      fallbackExercises: fallbackExercises,
    );

    final rawGuidelines = response['orientacoes'];
    final guidelines = <String>[];
    if (rawGuidelines is List) {
      for (final item in rawGuidelines) {
        if (item is String && item.trim().isNotEmpty) {
          guidelines.add(item.trim());
        }
      }
    }

    final role = TrainingViewerRole.fromApi(response['cargo'] as String?);

    return TrainingDetailData(
      code: code,
      title: rawTitle.trim(),
      description: description,
      estimatedDurationMinutes: estimatedDuration,
      exercises: List.unmodifiable(exercises),
      guidelines: List.unmodifiable(guidelines),
      role: role,
    );
  }

  List<TrainingDetailExercise> _parseExercises(
    Object? rawExercises, {
    List<TrainingExerciseItem>? fallbackExercises,
  }) {
    if (rawExercises is! List) return const [];
    final exercises = <TrainingDetailExercise>[];

    for (var i = 0; i < rawExercises.length; i++) {
      final entry = rawExercises[i];
      if (entry is! Map) continue;

      final code = _extractCode(entry['codigo'] ?? entry['code'], fallback: '');
      final rawName = entry['nome'] ?? entry['name'];
      final name = rawName is String ? rawName.trim() : '';
      if (name.isEmpty) continue;

      final duration = _parseInt(
        entry['duracao'] ?? entry['duracaoPadraoMinutos'],
      );
      final rawDesc = entry['descricao'] ?? entry['description'];
      var description = rawDesc is String ? rawDesc.trim() : '';

      final rawTipo = entry['tipo'];
      ExerciseType? exerciseType;
      if (rawTipo is String) {
        final normalizedTipo = rawTipo.trim().toLowerCase();
        if (normalizedTipo == 'especifico' || normalizedTipo == 'específico') {
          exerciseType = ExerciseType.specific;
        } else if (normalizedTipo == 'generico' || normalizedTipo == 'genérico') {
          exerciseType = ExerciseType.generic;
        }
      }

      TrainerLinkedHorse? horse;
      final rawHorse = entry['cavalo'];
      if (rawHorse is Map) {
        final horseId = _extractId(
          rawHorse['id'] ?? rawHorse['_id'] ?? rawHorse['codigo'],
        );
        final horseName = rawHorse['nome'] ?? rawHorse['name'];
        if (horseName is String && horseName.trim().isNotEmpty) {
          horse = TrainerLinkedHorse(
            id: horseId.isNotEmpty ? horseId : horseName.trim(),
            name: horseName.trim(),
          );
        }
      }

      if (description.isEmpty &&
          fallbackExercises != null &&
          i < fallbackExercises.length) {
        description = fallbackExercises[i].description?.trim() ?? '';
      }

      exercises.add(
        TrainingDetailExercise(
          code: code,
          id: _extractId(entry['id'] ?? entry['_id']).isNotEmpty
              ? _extractId(entry['id'] ?? entry['_id'])
              : null,
          name: name,
          durationMinutes: duration,
          description: description,
          exerciseType: exerciseType,
          horse: horse,
        ),
      );
    }

    return exercises;
  }

  TrainingDetailFailure _toFailure(
    FirebaseFunctionsException error, {
    required String defaultMessage,
  }) {
    return switch (error.code) {
      'unauthenticated' => TrainingDetailFailure(
        error.message ??
            'Entre novamente na sua conta para acessar o treinamento.',
      ),
      'permission-denied' => TrainingDetailFailure(
        error.message ??
            'Você não tem permissão para editar este treinamento.',
      ),
      'not-found' => TrainingDetailFailure(
        error.message ?? 'Treinamento não encontrado.',
      ),
      'invalid-argument' => TrainingDetailFailure(
        error.message ?? 'Dados do treinamento inválidos.',
      ),
      _ => TrainingDetailFailure(error.message ?? defaultMessage),
    };
  }

  String _extractCode(Object? rawValue, {required String fallback}) {
    return switch (rawValue) {
      final String value when value.trim().isNotEmpty => value.trim(),
      final int value when value > 0 => value.toString(),
      final num value when value > 0 => value.toInt().toString(),
      _ => fallback,
    };
  }

  String _extractId(Object? rawId) {
    return switch (rawId) {
      final String value when value.trim().isNotEmpty => value.trim(),
      final Map<Object?, Object?> oidMap when oidMap[r'$oid'] is String =>
        (oidMap[r'$oid'] as String).trim(),
      _ => '',
    };
  }

  int _parseInt(Object? rawValue) {
    return switch (rawValue) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value.trim()) ?? 0,
      _ => 0,
    };
  }

  Future<Object?> _callDetailFromFirebase(Map<String, Object?> payload) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_detailFunctionName).call<dynamic>(payload);
    return result.data;
  }

  Future<Object?> _callUpdateFromFirebase(Map<String, Object?> payload) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_updateFunctionName).call<dynamic>(payload);
    return result.data;
  }

  Future<Object?> _callGetExerciseFromFirebase(
    Map<String, Object?> payload,
  ) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_exerciseFunctionName).call<dynamic>(payload);
    return result.data;
  }
}
