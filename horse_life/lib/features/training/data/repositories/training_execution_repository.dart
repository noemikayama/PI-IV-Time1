// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Preservação do caminho relativo (path) das mídias retornadas por
// getExercise para compatibilidade com o carrossel reutilizado na execução.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Propagação da permissão de início da referência para os detalhes
// consolidados da execução.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Correção e ampliação dos comentários sobre as três etapas de
// consulta, enriquecimento tolerante dos exercícios e validação dos payloads.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do repositório que resolve o treino agendado no plano e
// combina detalhes, exercícios, materiais e mídias retornados pelas callables.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:horse_life/features/training/data/models/training_execution_data.dart';

/// Porta de leitura dos detalhes necessários para executar um treino.
abstract interface class TrainingExecutionLoader {
  Future<TrainingExecutionData> fetchTraining(
    TrainingExecutionReference reference,
  );
}

/// Assinatura comum das callables injetadas nos testes e na implementação.
typedef TrainingExecutionCallable =
    Future<dynamic> Function(Map<String, dynamic> payload);

/// Compõe as consultas de plano, treinamento e exercício existentes no backend.
///
/// O plano resolve o código associado à data e ao título; os detalhes do treino
/// fornecem o conteúdo principal; cada exercício é enriquecido separadamente.
class FirebaseTrainingExecutionRepository implements TrainingExecutionLoader {
  FirebaseTrainingExecutionRepository({
    FirebaseFunctions? functions,
    TrainingExecutionCallable? getPlanDetails,
    TrainingExecutionCallable? getTrainingDetails,
    TrainingExecutionCallable? getExercise,
  }) : _getPlanDetails =
           getPlanDetails ?? _firebaseCall(functions, 'getTrainingPlanDetails'),
       _getTrainingDetails =
           getTrainingDetails ?? _firebaseCall(functions, 'getTrainingDetails'),
       _getExercise = getExercise ?? _firebaseCall(functions, 'getExercise');

  final TrainingExecutionCallable _getPlanDetails;
  final TrainingExecutionCallable _getTrainingDetails;
  final TrainingExecutionCallable _getExercise;

  // Cria um adaptador uniforme para as callables da mesma região.
  static TrainingExecutionCallable _firebaseCall(
    FirebaseFunctions? functions,
    String name,
  ) =>
      (payload) async =>
          (await (functions ??
                      FirebaseFunctions.instanceFor(
                        region: 'southamerica-east1',
                      ))
                  .httpsCallable(name)
                  .call<dynamic>(payload))
              .data;

  @override
  /// Localiza o treino no plano e consolida seus detalhes e exercícios.
  ///
  /// Falhas nos dados principais interrompem a carga com [FormatException].
  /// Falhas apenas nos recursos de um exercício preservam seu conteúdo básico.
  Future<TrainingExecutionData> fetchTraining(
    TrainingExecutionReference reference,
  ) async {
    if (reference.planId.trim().isEmpty) {
      throw const FormatException('Plano do treino não identificado.');
    }
    final planResponse = await _getPlanDetails({'planoId': reference.planId});
    final plan = _asMap(planResponse, 'plano');
    final allTrainings = _asMap(plan['todosOsTreinos'], 'todosOsTreinos');
    final scheduled = _asList(
      allTrainings['treinos'],
      'todosOsTreinos.treinos',
    );
    final date = _formatDate(reference.date);

    // Data e título formam a chave disponível no cronograma retornado pelo plano.
    Map<String, dynamic>? match;
    for (final value in scheduled) {
      final item = _asMap(value, 'todosOsTreinos.treinos[]');
      final training = _asMap(
        item['treinamento'],
        'todosOsTreinos.treinos[].treinamento',
      );
      if (item['data'] == date && training['titulo'] == reference.title) {
        match = training;
        break;
      }
    }
    if (match == null) {
      throw const FormatException('Treino não localizado no plano.');
    }

    final code = _asString(match['codigo'], 'treinamento.codigo');
    final detailResponse = await _getTrainingDetails({'codigo': code});
    final detail = _asMap(detailResponse, 'treinamento');
    final baseExercises = _asList(detail['exercicios'], 'exercicios')
        .map((value) {
          final item = _asMap(value, 'exercicios[]');
          return TrainingExecutionExercise(
            code: _asString(item['codigo'], 'exercicios[].codigo'),
            name: _asString(item['nome'], 'exercicios[].nome'),
            durationMinutes: _asInt(item['duracao'], 'exercicios[].duracao'),
            description: item['descricao'] is String
                ? item['descricao'] as String
                : '',
          );
        })
        .toList(growable: false);
    final exercises = await Future.wait(
      baseExercises.map(_loadExerciseResources),
    );
    final guidelines = _asList(
      detail['orientacoes'],
      'orientacoes',
    ).map((value) => _asString(value, 'orientacoes[]')).toList(growable: false);

    return TrainingExecutionData(
      recordId: reference.recordId,
      title: _asString(detail['titulo'], 'titulo'),
      durationMinutes: _asInt(detail['duracaoEstimada'], 'duracaoEstimada'),
      description: detail['descricao'] is String
          ? detail['descricao'] as String
          : '',
      guidelines: guidelines,
      exercises: exercises,
      isFinished: reference.isFinished,
      canStart: reference.canStart,
    );
  }

  // Enriquece cada exercício de forma tolerante para que um recurso removido
  // não torne todo o treinamento indisponível.
  Future<TrainingExecutionExercise> _loadExerciseResources(
    TrainingExecutionExercise exercise,
  ) async {
    try {
      final response = await _getExercise({'codigo': exercise.code});
      final detail = _asMap(response, 'exercicio');
      final guidelines = _asList(detail['orientacoes'], 'orientacoes')
          .map((value) => _asString(value, 'orientacoes[]'))
          .toList(growable: false);
      final materials = _asList(detail['materiais'], 'materiais')
          .map((value) {
            final item = _asMap(value, 'materiais[]');
            return TrainingExerciseMaterial(
              description: _asString(
                item['descricao'],
                'materiais[].descricao',
              ),
              quantity: _asInt(item['quantidade'], 'materiais[].quantidade'),
            );
          })
          .toList(growable: false);
      final media = <TrainingExerciseMedia>[
        ..._mediaFrom(detail['imagens'], TrainingExerciseMediaType.image),
        ..._mediaFrom(detail['videos'], TrainingExerciseMediaType.video),
      ];
      return exercise.copyWith(
        guidelines: guidelines,
        materials: materials,
        media: List.unmodifiable(media),
      );
    } catch (_) {
      // A cópia do treinamento continua utilizável mesmo se o exercício de
      // origem tiver sido removido ou uma URL assinada não puder ser gerada.
      return exercise;
    }
  }

  // Converte imagens e vídeos com a mesma regra, preservando o tipo visual.
  List<TrainingExerciseMedia> _mediaFrom(
    Object? value,
    TrainingExerciseMediaType type,
  ) => _asList(value, type.name)
      .map((raw) {
        final item = _asMap(raw, '${type.name}[]');
        final rawPath =
            item['caminho'] ?? item['path'] ?? item['storagePath'] ?? '';
        return TrainingExerciseMedia(
          url: _asString(item['url'], '${type.name}[].url'),
          type: type,
          path: rawPath is String ? rawPath.trim() : '',
        );
      })
      .toList(growable: false);
}

// Validadores compartilhados mantêm os caminhos dos campos nas mensagens.
Map<String, dynamic> _asMap(Object? value, String field) {
  if (value is! Map) throw FormatException('Campo $field inválido.');
  return Map<String, dynamic>.from(value);
}

List<dynamic> _asList(Object? value, String field) {
  if (value is! List) throw FormatException('Campo $field inválido.');
  return value;
}

String _asString(Object? value, String field) {
  if (value is String && value.isNotEmpty) return value;
  if (value is num) return value.toString();
  throw FormatException('Campo $field inválido.');
}

int _asInt(Object? value, String field) {
  if (value is num) return value.toInt();
  throw FormatException('Campo $field inválido.');
}

// Serializa apenas a data civil usada no cronograma do plano.
String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
