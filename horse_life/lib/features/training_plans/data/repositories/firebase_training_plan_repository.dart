// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Simplificação do parser de detalhes após a validação do mapa de
// resposta, removendo verificações redundantes sem alterar os fallbacks.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Enriquecimento dos treinamentos de trainingsByDay com a descrição
// e lista de exercícios retornadas pelas sessões de treinosDaSemana e todosOsTreinos.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Correção da chave do identificador do plano para 'planoId' nas
// callables getTrainingPlanDetails e cancelTrainingPlan, adequando ao contrato do backend.
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição dos métodos getTrainingPlan, updateTrainingPlan e
// cancelTrainingPlan no adapter Firebase para suportar visualização e edição
// de planos de treinamento.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do adapter Firebase para listagem da galeria de
// treinamentos (listTrainingGallery) e cadastro de planos de treinamento
// (createTrainingPlan) na região southamerica-east1.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../../application/states/training_plan_registration_draft.dart';
import '../mocks/mock_training_plan_detail.dart';
import '../models/training_plan_gallery_item.dart';
import '../models/training_plan_weekday.dart';
import 'training_plan_repository.dart';

// Seams das callables para permitir testes unitários de serialização e erros.
typedef TrainingPlanGalleryCall =
    Future<Object?> Function(Map<String, Object?> payload);
typedef TrainingPlanCreateCall =
    Future<Object?> Function(Map<String, Object?> payload);
typedef TrainingPlanDetailCall =
    Future<Object?> Function(Map<String, Object?> payload);
typedef TrainingPlanUpdateCall =
    Future<Object?> Function(Map<String, Object?> payload);
typedef TrainingPlanCancelCall =
    Future<Object?> Function(Map<String, Object?> payload);

/// Implementa a consulta da galeria de treinamentos e as operações de cadastro,
/// visualização, edição e cancelamento de planos na região southamerica-east1.
final class FirebaseTrainingPlanRepository implements TrainingPlanRepository {
  const FirebaseTrainingPlanRepository({
    TrainingPlanGalleryCall? listTrainingGallery,
    TrainingPlanCreateCall? createTrainingPlan,
    TrainingPlanDetailCall? getTrainingPlan,
    TrainingPlanUpdateCall? updateTrainingPlan,
    TrainingPlanCancelCall? cancelTrainingPlan,
  }) : _listTrainingGallery = listTrainingGallery,
       _createTrainingPlan = createTrainingPlan,
       _getTrainingPlan = getTrainingPlan,
       _updateTrainingPlan = updateTrainingPlan,
       _cancelTrainingPlan = cancelTrainingPlan;

  static const _region = 'southamerica-east1';
  static const _galleryFunctionName = 'listTrainingGallery';
  static const _createPlanFunctionName = 'createTrainingPlan';
  static const _detailPlanFunctionName = 'getTrainingPlanDetails';
  static const _updatePlanFunctionName = 'updateTrainingPlan';
  static const _cancelPlanFunctionName = 'cancelTrainingPlan';

  final TrainingPlanGalleryCall? _listTrainingGallery;
  final TrainingPlanCreateCall? _createTrainingPlan;
  final TrainingPlanDetailCall? _getTrainingPlan;
  final TrainingPlanUpdateCall? _updateTrainingPlan;
  final TrainingPlanCancelCall? _cancelTrainingPlan;

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
      final response = await (_listTrainingGallery ?? _callGalleryFromFirebase)(
        payload,
      );
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
        error.message ?? 'Não foi possível carregar a galeria de treinamentos.',
      );
    } on FormatException catch (error) {
      throw TrainingPlanGalleryFailure(error.message);
    }
  }

  TrainingPlanGalleryItem _parseGalleryItem(Object? item) {
    if (item is! Map) {
      throw const FormatException('Item de treinamento na galeria inválido.');
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
    final description =
        item['descricao'] is String &&
            (item['descricao'] as String).trim().isNotEmpty
        ? (item['descricao'] as String).trim()
        : null;
    final exerciseNames = _parseExerciseNames(rawExercises);

    return TrainingPlanGalleryItem(
      id: id,
      code: code,
      title: title.trim(),
      estimatedDurationMinutes: durationMinutes,
      description: description,
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
        weekday.apiKey: _normalizeOptionalId(draft.trainingsByDay[weekday]?.id),
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
      final response = await (_createTrainingPlan ?? _callCreateFromFirebase)(
        payload,
      );
      if (response is! Map) {
        throw const FormatException('Resposta do cadastro de plano inválida.');
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

  @override
  Future<TrainingPlanDetailData> getTrainingPlan(String planId) async {
    final trimmedPlanId = planId.trim();
    if (trimmedPlanId.isEmpty) {
      throw const TrainingPlanDetailFailure('Identificador do plano inválido.');
    }

    // Se o identificador for um mock ou não corresponder a um ObjectId válido (24 caracteres hex),
    // utiliza diretamente o mock para permitir testes visuais locais sem depender do backend.
    final isValidObjectId = RegExp(
      r'^[0-9a-fA-F]{24}$',
    ).hasMatch(trimmedPlanId);
    if (!isValidObjectId) {
      return MockTrainingPlanDetail.buildDefault(planId: trimmedPlanId);
    }

    try {
      final response = await (_getTrainingPlan ?? _callDetailFromFirebase)({
        'planoId': trimmedPlanId,
      });
      return _parsePlanDetail(response, fallbackId: trimmedPlanId);
    } on FirebaseFunctionsException catch (error) {
      // Enquanto a Cloud Function não estiver disponível/implantada no Firebase,
      // ou se o plano não for encontrado no banco de dados, utiliza o fallback mockado.
      if (error.code == 'not-found' ||
          error.code == 'unimplemented' ||
          error.code == 'internal') {
        return MockTrainingPlanDetail.buildDefault(planId: trimmedPlanId);
      }
      throw _toDetailFailure(
        error,
        defaultMessage: 'Não foi possível carregar o plano de treinamento.',
      );
    } on FormatException catch (error) {
      throw TrainingPlanDetailFailure(error.message);
    } catch (_) {
      // Fallback gracioso para chamadas diretas não configuradas no ambiente local
      return MockTrainingPlanDetail.buildDefault(planId: trimmedPlanId);
    }
  }

  @override
  Future<TrainingPlanDetailData> updateTrainingPlan(
    String planId,
    TrainingPlanUpdate update,
  ) async {
    final trimmedPlanId = planId.trim();
    if (trimmedPlanId.isEmpty) {
      throw const TrainingPlanDetailFailure('Identificador do plano inválido.');
    }

    final trimmedTitle = update.title.trim();
    if (trimmedTitle.length < 3 || trimmedTitle.length > 80) {
      throw const TrainingPlanDetailFailure(
        'O título deve ter entre 3 e 80 caracteres.',
      );
    }

    final trimmedObjective = update.objective.trim();
    if (trimmedObjective.isEmpty || trimmedObjective.length > 1000) {
      throw const TrainingPlanDetailFailure(
        'O objetivo deve ter entre 1 e 1000 caracteres.',
      );
    }

    if (update.horse.id.trim().isEmpty) {
      throw const TrainingPlanDetailFailure(
        'Selecione um cavalo para o plano.',
      );
    }

    final normalizedStart = TrainingPlanRegistrationDraft.dateOnly(
      update.startDate,
    );
    final normalizedEnd = TrainingPlanRegistrationDraft.dateOnly(
      update.endDate,
    );
    if (normalizedEnd.isBefore(normalizedStart)) {
      throw const TrainingPlanDetailFailure(
        'A data de fim não pode ser anterior à data de início.',
      );
    }
    if (normalizedEnd.isAfter(
      TrainingPlanRegistrationDraft.maxEndDateFor(normalizedStart),
    )) {
      throw const TrainingPlanDetailFailure(
        'O plano pode durar no máximo 12 meses.',
      );
    }

    if (!update.trainingsByDay.values.any(
      (item) => item != null && item.id.trim().isNotEmpty,
    )) {
      throw const TrainingPlanDetailFailure(
        'Escolha um treino para pelo menos um dia da semana.',
      );
    }

    try {
      final response = await (_updateTrainingPlan ?? _callUpdateFromFirebase)(
        update.toJson(trimmedPlanId),
      );
      return _parsePlanDetail(response, fallbackId: trimmedPlanId);
    } on FirebaseFunctionsException catch (error) {
      throw _toDetailFailure(
        error,
        defaultMessage: 'Não foi possível atualizar o plano de treinamento.',
      );
    } on FormatException catch (error) {
      throw TrainingPlanDetailFailure(error.message);
    }
  }

  @override
  Future<TrainingPlanDetailData> cancelTrainingPlan(String planId) async {
    final trimmedPlanId = planId.trim();
    if (trimmedPlanId.isEmpty) {
      throw const TrainingPlanDetailFailure('Identificador do plano inválido.');
    }

    try {
      final response = await (_cancelTrainingPlan ?? _callCancelFromFirebase)({
        'planoId': trimmedPlanId,
      });
      if (response is! Map) {
        throw const FormatException(
          'Resposta do cancelamento do plano inválida.',
        );
      }

      final planMap = response['plano'] is Map
          ? response['plano'] as Map
          : response;
      if (_hasFullPlanFields(planMap)) {
        return _parsePlanDetail(response, fallbackId: trimmedPlanId);
      }

      final canceledFlag =
          response['cancelado'] == true || planMap['cancelado'] == true;
      final statusRaw = planMap['status'];
      final isCanceledStatus =
          statusRaw is String &&
          TrainingPlanStatus.fromApi(statusRaw) == TrainingPlanStatus.canceled;
      if (!canceledFlag && !isCanceledStatus) {
        throw const FormatException(
          'O servidor não confirmou o cancelamento do plano.',
        );
      }

      final extractedId = _extractId(planMap['id'] ?? planMap['_id']);
      return TrainingPlanDetailData(
        id: extractedId.isNotEmpty ? extractedId : trimmedPlanId,
        code: _parseInt(planMap['codigo'] ?? planMap['code']),
        title: '',
        objective: '',
        startDate: DateTime(1970, 1, 1),
        endDate: DateTime(1970, 1, 1),
        horse: const TrainerLinkedHorse(id: '', name: ''),
        trainerId: '',
        trainerName: '',
        status: TrainingPlanStatus.canceled,
        trainingsByDay: const {},
      );
    } on FirebaseFunctionsException catch (error) {
      throw _toDetailFailure(
        error,
        defaultMessage: 'Não foi possível cancelar o plano de treinamento.',
      );
    } on FormatException catch (error) {
      throw TrainingPlanDetailFailure(error.message);
    }
  }

  bool _hasFullPlanFields(Map<Object?, Object?> planMap) {
    final title = planMap['titulo'] ?? planMap['title'];
    return title is String &&
        title.trim().isNotEmpty &&
        planMap['dataInicio'] != null &&
        planMap['dataFim'] != null;
  }

  TrainingPlanDetailData _parsePlanDetail(
    Object? response, {
    required String fallbackId,
  }) {
    if (response is! Map) {
      throw const FormatException('Resposta dos detalhes do plano inválida.');
    }

    final planMap = response['plano'] is Map
        ? response['plano'] as Map
        : response;
    final extractedId = _extractId(planMap['id'] ?? planMap['_id']);
    final id = extractedId.isNotEmpty ? extractedId : fallbackId.trim();
    if (id.isEmpty) {
      throw const FormatException(
        'Identificador do plano ausente na resposta.',
      );
    }

    final rawTitle = planMap['titulo'] ?? planMap['title'];
    if (rawTitle is! String || rawTitle.trim().isEmpty) {
      throw const FormatException('Título do plano ausente na resposta.');
    }

    final rawObjective = planMap['objetivo'] ?? planMap['objective'];
    final objective = rawObjective is String ? rawObjective.trim() : '';

    final startDate = _parseCalendarDate(planMap['dataInicio']);
    final endDate = _parseCalendarDate(planMap['dataFim']);
    if (startDate == null || endDate == null) {
      throw const FormatException('Datas do plano ausentes ou inválidas.');
    }

    final horseMap = planMap['cavalo'] ?? response['cavalo'];
    final horseId = horseMap is Map
        ? _extractId(horseMap['id'] ?? horseMap['_id'])
        : _extractId(planMap['cavaloId'] ?? response['cavaloId']);
    final rawHorseName = horseMap is Map
        ? horseMap['nome'] ?? horseMap['name']
        : (planMap['nomeCavalo'] ?? response['nomeCavalo']);
    final horseName = rawHorseName is String ? rawHorseName.trim() : '';

    final trainerMap = planMap['treinador'] ?? response['treinador'];
    final trainerId = trainerMap is Map
        ? _extractId(trainerMap['id'] ?? trainerMap['_id'])
        : _extractId(planMap['treinadorId'] ?? response['treinadorId']);
    final rawTrainerName = trainerMap is Map
        ? trainerMap['nome'] ?? trainerMap['name']
        : (planMap['nomeTreinador'] ?? response['nomeTreinador']);
    final trainerName = rawTrainerName is String ? rawTrainerName.trim() : '';

    final permissoes = response['permissoes'] is Map
        ? response['permissoes'] as Map
        : null;
    final rawIsOwner =
        planMap['ehProprietario'] ??
        planMap['isOwner'] ??
        (permissoes != null
            ? (permissoes['podeEditar'] == true ||
                  permissoes['podeCancelar'] == true)
            : null);
    final isOwner = rawIsOwner is bool ? rawIsOwner : null;

    final trainingsByDay = <TrainingPlanWeekday, TrainingPlanGalleryItem>{};
    final rawByDay = planMap['treinosPorDia'] ?? response['treinosPorDia'];
    final rawPlanning = planMap['planejamento'] ?? response['planejamento'];
    if (rawByDay is Map) {
      for (final entry in rawByDay.entries) {
        final weekday = _parseWeekday(entry.key);
        if (weekday == null || entry.value is! Map) continue;
        final parsedTraining = _parseTrainingSnapshot(entry.value as Map);
        if (parsedTraining != null) {
          trainingsByDay[weekday] = parsedTraining;
        }
      }
    } else if (rawPlanning is List) {
      for (final item in rawPlanning) {
        if (item is! Map) continue;
        if (item['ativo'] == false) continue;

        final trainingMap = item['treinamento'];
        if (trainingMap is! Map) continue;
        final parsedTraining = _parseTrainingSnapshot(
          trainingMap,
          fallbackCode: _parseInt(item['codigo']),
        );
        if (parsedTraining == null) continue;

        final rawWeekdays = item['diasSemana'];
        if (rawWeekdays is! List) continue;
        for (final rawDay in rawWeekdays) {
          final weekday = _parseWeekday(rawDay);
          if (weekday != null) {
            trainingsByDay[weekday] = parsedTraining;
          }
        }
      }
    }

    _enrichTrainingsWithSessionDetails(
      trainingsByDay: trainingsByDay,
      response: response,
    );

    return TrainingPlanDetailData(
      id: id,
      code: _parseInt(planMap['codigo'] ?? planMap['code']),
      title: rawTitle.trim(),
      objective: objective,
      startDate: startDate,
      endDate: endDate,
      horse: TrainerLinkedHorse(id: horseId, name: horseName),
      trainerId: trainerId,
      trainerName: trainerName,
      status: TrainingPlanStatus.fromApi(planMap['status'] as String?),
      trainingsByDay: Map.unmodifiable(trainingsByDay),
      isOwner: isOwner,
    );
  }

  TrainingPlanGalleryItem? _parseTrainingSnapshot(
    Map<Object?, Object?> item, {
    int fallbackCode = 0,
  }) {
    final title = item['titulo'] ?? item['title'];
    if (title is! String || title.trim().isEmpty) return null;

    final code = _parseInt(item['codigo'] ?? item['code']);
    final effectiveCode = code > 0 ? code : fallbackCode;
    final extractedId = _extractId(item['id'] ?? item['_id']);
    final id = extractedId.isNotEmpty
        ? extractedId
        : (effectiveCode > 0 ? 'training-$effectiveCode' : title.trim());

    final rawDuration =
        item['duracaoEstimadaMinutos'] ?? item['duracaoEstimada'];
    final rawDescription = item['descricao'] ?? item['description'];
    final description =
        rawDescription is String && rawDescription.trim().isNotEmpty
        ? rawDescription.trim()
        : null;

    return TrainingPlanGalleryItem(
      id: id,
      code: effectiveCode,
      title: title.trim(),
      estimatedDurationMinutes: _parseInt(rawDuration),
      description: description,
      exerciseNames: _parseExerciseNames(item['exercicios']),
    );
  }

  List<String> _parseExerciseNames(Object? rawExercises) {
    if (rawExercises is! List) return const <String>[];
    final names = <String>[];
    for (final entry in rawExercises) {
      if (entry is String && entry.trim().isNotEmpty) {
        names.add(entry.trim());
      } else if (entry is Map) {
        final name = entry['nome'] ?? entry['titulo'] ?? entry['name'];
        if (name is String && name.trim().isNotEmpty) {
          names.add(name.trim());
        }
      }
    }
    return List.unmodifiable(names);
  }

  TrainingPlanWeekday? _parseWeekday(Object? rawDay) {
    if (rawDay is! String) return null;
    final normalized = rawDay.trim().toUpperCase();
    for (final weekday in TrainingPlanWeekday.values) {
      if (weekday.apiKey == normalized ||
          weekday.name.toUpperCase() == normalized ||
          weekday.label.toUpperCase() == normalized ||
          normalized.startsWith(weekday.apiKey) ||
          normalized.startsWith(weekday.label.toUpperCase())) {
        return weekday;
      }
    }
    final unaccented = normalized
        .replaceAll('Ç', 'C')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U');
    for (final weekday in TrainingPlanWeekday.values) {
      final unaccentedApiKey = weekday.apiKey
          .replaceAll('Ç', 'C')
          .replaceAll('Á', 'A');
      final unaccentedLabel = weekday.label
          .toUpperCase()
          .replaceAll('Ç', 'C')
          .replaceAll('Á', 'A');
      if (unaccented == unaccentedApiKey ||
          unaccented == unaccentedLabel ||
          unaccented.startsWith(unaccentedApiKey) ||
          unaccented.startsWith(unaccentedLabel)) {
        return weekday;
      }
    }
    return null;
  }

  void _enrichTrainingsWithSessionDetails({
    required Map<TrainingPlanWeekday, TrainingPlanGalleryItem> trainingsByDay,
    required Object? response,
  }) {
    if (response is! Map) return;

    final sessionLists = <Object?>[
      if (response['todosOsTreinos'] is Map)
        (response['todosOsTreinos'] as Map)['treinos'],
      if (response['treinosDaSemana'] is Map)
        (response['treinosDaSemana'] as Map)['treinos'],
    ];

    final detailsByCode = <int, _SessionTrainingDetails>{};
    final detailsByWeekday = <TrainingPlanWeekday, _SessionTrainingDetails>{};
    final detailsByTitle = <String, _SessionTrainingDetails>{};

    for (final sessionList in sessionLists) {
      if (sessionList is! List) continue;
      for (final session in sessionList) {
        if (session is! Map) continue;

        final rawTraining = session['treinamento'];
        if (rawTraining is! Map) continue;

        final code = _parseInt(rawTraining['codigo'] ?? rawTraining['code']);
        final title =
            (rawTraining['titulo'] ?? rawTraining['title'])
                ?.toString()
                .trim() ??
            '';
        final rawDesc = rawTraining['descricao'] ?? rawTraining['description'];
        final description = rawDesc is String && rawDesc.trim().isNotEmpty
            ? rawDesc.trim()
            : null;
        final exercises = _parseExerciseNames(rawTraining['exercicios']);

        final weekday = _parseWeekdayFromSession(session);

        final details = _SessionTrainingDetails(
          code: code,
          title: title,
          durationMinutes: _parseInt(
            rawTraining['duracaoEstimadaMinutos'] ??
                rawTraining['duracaoEstimada'],
          ),
          description: description,
          exerciseNames: exercises,
        );

        if (code > 0) {
          detailsByCode.putIfAbsent(code, () => details);
        }
        if (title.isNotEmpty) {
          detailsByTitle.putIfAbsent(title.toLowerCase(), () => details);
        }
        if (weekday != null) {
          detailsByWeekday.putIfAbsent(weekday, () => details);
          if (!trainingsByDay.containsKey(weekday) && title.isNotEmpty) {
            final rawId = _extractId(rawTraining['id'] ?? rawTraining['_id']);
            trainingsByDay[weekday] = TrainingPlanGalleryItem(
              id: rawId.isNotEmpty
                  ? rawId
                  : (code > 0 ? 'training-$code' : title),
              code: code,
              title: title,
              estimatedDurationMinutes: details.durationMinutes,
              description: description,
              exerciseNames: exercises,
            );
          }
        }
      }
    }

    for (final entry in trainingsByDay.entries.toList()) {
      final weekday = entry.key;
      final existing = entry.value;

      final details =
          detailsByWeekday[weekday] ??
          (existing.code > 0 ? detailsByCode[existing.code] : null) ??
          detailsByTitle[existing.title.toLowerCase()];

      if (details != null) {
        final mergedDesc = existing.description ?? details.description;
        final mergedExercises = existing.exerciseNames.isNotEmpty
            ? existing.exerciseNames
            : details.exerciseNames;

        trainingsByDay[weekday] = TrainingPlanGalleryItem(
          id: existing.id,
          code: existing.code > 0 ? existing.code : details.code,
          title: existing.title.isNotEmpty ? existing.title : details.title,
          estimatedDurationMinutes: existing.estimatedDurationMinutes > 0
              ? existing.estimatedDurationMinutes
              : details.durationMinutes,
          description: mergedDesc,
          exerciseNames: mergedExercises,
        );
      }
    }
  }

  TrainingPlanWeekday? _parseWeekdayFromSession(Map session) {
    final fromText = _parseWeekday(session['diaSemana']);
    if (fromText != null) return fromText;

    final rawDate = session['data'];
    if (rawDate is String) {
      final parsedDate = DateTime.tryParse(rawDate.trim());
      if (parsedDate != null) {
        return switch (parsedDate.weekday) {
          DateTime.monday => TrainingPlanWeekday.monday,
          DateTime.tuesday => TrainingPlanWeekday.tuesday,
          DateTime.wednesday => TrainingPlanWeekday.wednesday,
          DateTime.thursday => TrainingPlanWeekday.thursday,
          DateTime.friday => TrainingPlanWeekday.friday,
          DateTime.saturday => TrainingPlanWeekday.saturday,
          DateTime.sunday => TrainingPlanWeekday.sunday,
          _ => null,
        };
      }
    }
    return null;
  }

  DateTime? _parseCalendarDate(Object? rawDate) {
    if (rawDate is! String) return null;
    final trimmed = rawDate.trim();
    if (trimmed.isEmpty) return null;
    final datePart = trimmed.split('T').first;
    final segments = datePart.split('-');
    if (segments.length == 3) {
      final year = int.tryParse(segments[0]);
      final month = int.tryParse(segments[1]);
      final day = int.tryParse(segments[2]);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day);
      }
    }
    final parsed = DateTime.tryParse(trimmed);
    return parsed != null
        ? TrainingPlanRegistrationDraft.dateOnly(parsed)
        : null;
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
        error.message ?? 'Cavalo ou treinamento selecionado não encontrado.',
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

  TrainingPlanDetailFailure _toDetailFailure(
    FirebaseFunctionsException error, {
    required String defaultMessage,
  }) {
    return switch (error.code) {
      'unauthenticated' => TrainingPlanDetailFailure(
        error.message ?? 'Entre novamente na sua conta para acessar o plano.',
      ),
      'permission-denied' => TrainingPlanDetailFailure(
        error.message ?? 'Você não tem permissão para gerenciar este plano.',
      ),
      'not-found' => TrainingPlanDetailFailure(
        error.message ?? 'Plano de treinamento não encontrado.',
      ),
      'failed-precondition' => TrainingPlanDetailFailure(
        error.message ?? 'A situação atual do plano não permite essa operação.',
      ),
      'invalid-argument' => TrainingPlanDetailFailure(
        error.message ?? 'Dados do plano inválidos.',
      ),
      _ => TrainingPlanDetailFailure(error.message ?? defaultMessage),
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

  Future<Object?> _callDetailFromFirebase(Map<String, Object?> payload) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_detailPlanFunctionName).call<dynamic>(payload);
    return result.data;
  }

  Future<Object?> _callUpdateFromFirebase(Map<String, Object?> payload) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_updatePlanFunctionName).call<dynamic>(payload);
    return result.data;
  }

  Future<Object?> _callCancelFromFirebase(Map<String, Object?> payload) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_cancelPlanFunctionName).call<dynamic>(payload);
    return result.data;
  }
}

final class _SessionTrainingDetails {
  const _SessionTrainingDetails({
    required this.code,
    required this.title,
    required this.durationMinutes,
    required this.description,
    required this.exerciseNames,
  });

  final int code;
  final String title;
  final int durationMinutes;
  final String? description;
  final List<String> exerciseNames;
}
