// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do adapter Firebase para listagem da galeria de
// treinamentos (listTrainingGallery) e cadastro de planos de treinamento
// (createTrainingPlan) na região southamerica-east1.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import '../../application/states/training_plan_registration_draft.dart';
import '../models/training_plan_gallery_item.dart';
import '../models/training_plan_weekday.dart';
import 'training_plan_repository.dart';

// Seams das callables para permitir testes unitários de serialização e erros.
typedef TrainingPlanGalleryCall =
    Future<Object?> Function(Map<String, Object?> payload);
typedef TrainingPlanCreateCall =
    Future<Object?> Function(Map<String, Object?> payload);

/// Implementa a consulta da galeria de treinamentos e o cadastro de planos
/// usando as Cloud Functions `listTrainingGallery` e `createTrainingPlan`
/// conforme especificado em `docs/contrato_planos.md`.
final class FirebaseTrainingPlanRepository implements TrainingPlanRepository {
  const FirebaseTrainingPlanRepository({
    TrainingPlanGalleryCall? listTrainingGallery,
    TrainingPlanCreateCall? createTrainingPlan,
  }) : _listTrainingGallery = listTrainingGallery,
       _createTrainingPlan = createTrainingPlan;

  static const _region = 'southamerica-east1';
  static const _galleryFunctionName = 'listTrainingGallery';
  static const _createPlanFunctionName = 'createTrainingPlan';

  final TrainingPlanGalleryCall? _listTrainingGallery;
  final TrainingPlanCreateCall? _createTrainingPlan;

  @override
  Future<List<TrainingPlanGalleryItem>> fetchTrainingGallery({
    required String horseId,
    String? searchQuery,
  }) async {
    final trimmedHorseId = horseId.trim();
    if (trimmedHorseId.isEmpty) {
      throw const TrainingPlanGalleryFailure(
        'Cavalo inválido para carregar a galeria de treinamentos.',
      );
    }

    final trimmedSearch = searchQuery?.trim() ?? '';
    final payload = <String, Object?>{
      'cavaloId': trimmedHorseId,
      if (trimmedSearch.isNotEmpty) 'busca': trimmedSearch,
    };

    try {
      final response =
          await (_listTrainingGallery ?? _callGalleryFromFirebase)(payload);
      if (response is! Map) {
        throw const FormatException(
          'Resposta da galeria de treinamentos inválida.',
        );
      }

      final rawList = response['treinamentos'];
      if (rawList is! List) {
        throw const FormatException(
          'Lista de treinamentos da galeria inválida.',
        );
      }

      return rawList.map(_parseGalleryItem).toList(growable: false);
    } on FirebaseFunctionsException catch (error) {
      throw TrainingPlanGalleryFailure(
        error.message ??
            'Não foi possível carregar a galeria de treinamentos.',
      );
    } on FormatException catch (error) {
      throw TrainingPlanGalleryFailure(error.message);
    }
  }

  TrainingPlanGalleryItem _parseGalleryItem(Object? item) {
    if (item is! Map) {
      throw const FormatException(
        'Item de treinamento na galeria inválido.',
      );
    }

    final id = _extractId(item['id'] ?? item['_id']);
    final title = item['titulo'] ?? item['title'];
    final rawCode = item['codigo'] ?? item['code'];
    final rawDuration = item['duracaoEstimadaMinutos'];
    final rawExercises = item['exercicios'];

    if (id.isEmpty || title is! String || title.trim().isEmpty) {
      throw const FormatException(
        'Dados do treinamento na galeria incompletos.',
      );
    }

    final code = _parseInt(rawCode);
    final durationMinutes = _parseInt(rawDuration);
    final exerciseNames = rawExercises is List
        ? rawExercises
              .whereType<String>()
              .map((name) => name.trim())
              .where((name) => name.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return TrainingPlanGalleryItem(
      id: id,
      code: code,
      title: title.trim(),
      estimatedDurationMinutes: durationMinutes,
      exerciseNames: exerciseNames,
    );
  }

  @override
  Future<TrainingPlanRegistrationResult> createTrainingPlan({
    required TrainingPlanRegistrationDraft draft,
  }) async {
    final trimmedTitle = draft.title.trim();
    if (trimmedTitle.length < 3 || trimmedTitle.length > 80) {
      throw const TrainingPlanRegistrationFailure(
        'O título deve ter entre 3 e 80 caracteres.',
      );
    }

    final trimmedObjective = draft.objective.trim();
    if (trimmedObjective.isEmpty || trimmedObjective.length > 1000) {
      throw const TrainingPlanRegistrationFailure(
        'O objetivo deve ter entre 1 e 1000 caracteres.',
      );
    }

    final horseId = draft.horse?.id.trim() ?? '';
    if (horseId.isEmpty) {
      throw const TrainingPlanRegistrationFailure(
        'Selecione um cavalo para o plano.',
      );
    }

    final startDate = draft.startDate;
    final endDate = draft.endDate;
    if (startDate == null || endDate == null) {
      throw const TrainingPlanRegistrationFailure(
        'Informe as datas de início e fim do plano.',
      );
    }

    final normalizedStart = TrainingPlanRegistrationDraft.dateOnly(startDate);
    final normalizedEnd = TrainingPlanRegistrationDraft.dateOnly(endDate);
    final today = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());

    if (normalizedStart.isBefore(today)) {
      throw const TrainingPlanRegistrationFailure(
        'A data de início deve ser hoje ou uma data futura.',
      );
    }
    if (normalizedEnd.isBefore(normalizedStart)) {
      throw const TrainingPlanRegistrationFailure(
        'A data de fim não pode ser anterior à data de início.',
      );
    }
    if (normalizedEnd.isAfter(
      TrainingPlanRegistrationDraft.maxEndDateFor(normalizedStart),
    )) {
      throw const TrainingPlanRegistrationFailure(
        'O plano pode durar no máximo 12 meses.',
      );
    }

    final trainingsByDay = <String, String?>{
      for (final weekday in TrainingPlanWeekday.values)
        weekday.apiKey: _normalizeOptionalId(
          draft.trainingsByDay[weekday]?.id,
        ),
    };
    if (!trainingsByDay.values.any((id) => id != null)) {
      throw const TrainingPlanRegistrationFailure(
        'Escolha um treino para pelo menos um dia da semana.',
      );
    }

    final evaluationId = _normalizeOptionalId(draft.evaluationId);
    final payload = <String, Object?>{
      'titulo': trimmedTitle,
      'objetivo': trimmedObjective,
      'cavaloId': horseId,
      'avaliacaoId': evaluationId,
      'dataInicio': TrainingPlanRegistrationDraft.formatYmd(normalizedStart),
      'dataFim': TrainingPlanRegistrationDraft.formatYmd(normalizedEnd),
      'treinosPorDia': trainingsByDay,
    };

    try {
      final response =
          await (_createTrainingPlan ?? _callCreateFromFirebase)(payload);
      if (response is! Map) {
        throw const FormatException(
          'Resposta do cadastro de plano inválida.',
        );
      }

      final planMap = response['plano'];
      if (planMap is! Map) {
        throw const TrainingPlanRegistrationFailure(
          'O servidor não confirmou o cadastro do plano.',
        );
      }

      final id = _extractId(planMap['id'] ?? planMap['_id']);
      if (id.isEmpty) {
        throw const TrainingPlanRegistrationFailure(
          'O servidor não retornou o identificador do plano.',
        );
      }

      return TrainingPlanRegistrationResult(
        id: id,
        code: _parseInt(planMap['codigo'] ?? planMap['code']),
        status: planMap['status'] is String
            ? (planMap['status'] as String).trim()
            : 'ATIVO',
        startDate: planMap['dataInicio'] is String
            ? planMap['dataInicio'] as String
            : TrainingPlanRegistrationDraft.formatYmd(normalizedStart),
        endDate: planMap['dataFim'] is String
            ? planMap['dataFim'] as String
            : TrainingPlanRegistrationDraft.formatYmd(normalizedEnd),
        generatedRecordsCount: _parseInt(response['registrosGerados']),
      );
    } on FirebaseFunctionsException catch (error) {
      throw _toFailure(
        error,
        defaultMessage: 'Não foi possível cadastrar o plano de treinamento.',
      );
    } on FormatException catch (error) {
      throw TrainingPlanRegistrationFailure(error.message);
    }
  }

  TrainingPlanRegistrationFailure _toFailure(
    FirebaseFunctionsException error, {
    required String defaultMessage,
  }) {
    return switch (error.code) {
      'invalid-argument' => TrainingPlanRegistrationFailure(
        error.message ?? 'Dados do plano inválidos.',
      ),
      'not-found' => TrainingPlanRegistrationFailure(
        error.message ??
            'Cavalo ou treinamento selecionado não encontrado.',
      ),
      'failed-precondition' => TrainingPlanRegistrationFailure(
        error.message ?? 'Este cavalo já possui um plano ativo em andamento.',
      ),
      'permission-denied' => TrainingPlanRegistrationFailure(
        error.message ?? 'Você não tem permissão para cadastrar este plano.',
      ),
      _ => TrainingPlanRegistrationFailure(error.message ?? defaultMessage),
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

  String? _normalizeOptionalId(String? rawId) {
    final trimmed = rawId?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  int _parseInt(Object? rawValue) {
    return switch (rawValue) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
  }

  Future<Object?> _callGalleryFromFirebase(Map<String, Object?> payload) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_galleryFunctionName).call<dynamic>(payload);
    return result.data;
  }

  Future<Object?> _callCreateFromFirebase(Map<String, Object?> payload) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_createPlanFunctionName).call<dynamic>(payload);
    return result.data;
  }
}
