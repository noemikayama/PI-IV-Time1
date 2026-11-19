// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação defensiva exigindo ao menos uma orientação e conferindo que
// a duração estimada não seja inferior à soma dos exercícios antes do envio.
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do adapter Firebase para cálculo da soma de durações dos
// exercícios (sumExerciseDurations) e cadastro de treinamentos (registerTraining)
// na região southamerica-east1.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import '../../application/states/training_registration_draft.dart';
import '../models/training_exercise_item.dart';
import 'training_registration_repository.dart';

// Seams das callables para permitir testes unitários de serialização e erros.
typedef TrainingDurationSumCall =
    Future<Object?> Function(Map<String, Object?> payload);
typedef TrainingRegistrationCall =
    Future<Object?> Function(Map<String, Object?> payload);

/// Implementa o cálculo de duração total e o cadastro de treinamentos usando as
/// Cloud Functions `sumExerciseDurations` e `registerTraining` conforme
/// especificado em `docs/contrato_treinamentos.md`.
final class FirebaseTrainingRegistrationRepository
    implements TrainingRegistrationRepository {
  const FirebaseTrainingRegistrationRepository({
    TrainingDurationSumCall? sumExerciseDurations,
    TrainingRegistrationCall? registerTraining,
  }) : _sumExerciseDurations = sumExerciseDurations,
       _registerTraining = registerTraining;

  static const _region = 'southamerica-east1';
  static const _sumDurationsFunctionName = 'sumExerciseDurations';
  static const _registerTrainingFunctionName = 'registerTraining';

  final TrainingDurationSumCall? _sumExerciseDurations;
  final TrainingRegistrationCall? _registerTraining;

  @override
  Future<int> sumExerciseDurations({
    required List<TrainingExerciseItem> exercises,
  }) async {
    final ids = exercises
        .map((item) => item.id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);

    try {
      final response =
          await (_sumExerciseDurations ?? _callSumFromFirebase)({
            'exercicios': ids,
          });
      if (response is! Map) {
        throw const FormatException(
          'Resposta da soma de durações inválida.',
        );
      }

      final total = response['duracaoTotalMinutos'];
      return switch (total) {
        final int value => value,
        final num value => value.toInt(),
        _ => throw const FormatException(
          'Duração total dos exercícios inválida.',
        ),
      };
    } on FirebaseFunctionsException catch (error) {
      throw _toFailure(
        error,
        defaultMessage: 'Não foi possível calcular o tempo dos exercícios.',
      );
    } on FormatException catch (error) {
      throw TrainingRegistrationFailure(error.message);
    }
  }

  @override
  Future<TrainingRegistrationResult> registerTraining({
    required TrainingRegistrationDraft draft,
  }) async {
    final trimmedTitle = draft.title.trim();
    if (trimmedTitle.length < 3 || trimmedTitle.length > 80) {
      throw const TrainingRegistrationFailure(
        'O título deve ter entre 3 e 80 caracteres.',
      );
    }

    final trimmedDescription = draft.description.trim();
    if (trimmedDescription.length > 1000) {
      throw const TrainingRegistrationFailure(
        'A descrição deve ter no máximo 1000 caracteres.',
      );
    }

    final exerciseIds = draft.selectedExercises
        .map((exercise) => exercise.id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (exerciseIds.isEmpty || exerciseIds.length > 50) {
      throw const TrainingRegistrationFailure(
        'Selecione entre 1 e 50 exercícios para o treinamento.',
      );
    }

    final cleanGuidelines = draft.guidelines
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (cleanGuidelines.isEmpty) {
      throw const TrainingRegistrationFailure(
        'Adicione pelo menos uma orientação para cadastrar o treinamento.',
      );
    }
    if (cleanGuidelines.length > 30) {
      throw const TrainingRegistrationFailure(
        'Informe no máximo 30 orientações para o treinamento.',
      );
    }
    if (cleanGuidelines.any((item) => item.length > 500)) {
      throw const TrainingRegistrationFailure(
        'Cada orientação deve ter no máximo 500 caracteres.',
      );
    }

    final duration = draft.estimatedDurationMinutes;
    if (duration == null || duration < 1 || duration > 480) {
      throw const TrainingRegistrationFailure(
        'A duração estimada deve ser um número inteiro entre 1 e 480 minutos.',
      );
    }

    final totalExercisesDuration = draft.selectedExercises.fold<int>(
      0,
      (total, exercise) => total + exercise.estimatedDurationMinutes,
    );
    if (duration < totalExercisesDuration) {
      throw TrainingRegistrationFailure(
        'A duração estimada não pode ser menor que a soma dos exercícios ($totalExercisesDuration min).',
      );
    }

    final payload = <String, Object?>{
      'titulo': trimmedTitle,
      if (trimmedDescription.isNotEmpty) 'descricao': trimmedDescription,
      'exercicios': exerciseIds,
      'orientacoes': cleanGuidelines,
      'duracaoEstimadaMinutos': duration,
    };

    try {
      final response =
          await (_registerTraining ?? _callRegisterFromFirebase)(payload);
      if (response is! Map) {
        throw const FormatException(
          'Resposta do cadastro de treinamento inválida.',
        );
      }

      final id = response['id'];
      final rawCode = response['codigo'] ?? response['code'];
      final title = response['titulo'] ?? response['title'];

      if (id is! String ||
          id.isEmpty ||
          title is! String ||
          title.trim().isEmpty) {
        throw const TrainingRegistrationFailure(
          'O servidor não confirmou o cadastro do treinamento.',
        );
      }

      final code = switch (rawCode) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value) ?? 0,
        _ => 0,
      };

      return TrainingRegistrationResult(
        id: id,
        code: code,
        title: title.trim(),
      );
    } on FirebaseFunctionsException catch (error) {
      throw _toFailure(
        error,
        defaultMessage: 'Não foi possível cadastrar o treinamento.',
      );
    } on FormatException catch (error) {
      throw TrainingRegistrationFailure(error.message);
    }
  }

  TrainingRegistrationFailure _toFailure(
    FirebaseFunctionsException error, {
    required String defaultMessage,
  }) {
    return switch (error.code) {
      'invalid-argument' => TrainingRegistrationFailure(
        error.message ?? 'Dados do treinamento inválidos.',
      ),
      'permission-denied' => TrainingRegistrationFailure(
        error.message ??
            'Você não tem permissão para cadastrar este treinamento.',
      ),
      'not-found' => TrainingRegistrationFailure(
        error.message ??
            'Um ou mais exercícios selecionados não foram encontrados.',
      ),
      _ => TrainingRegistrationFailure(error.message ?? defaultMessage),
    };
  }

  Future<Object?> _callSumFromFirebase(Map<String, Object?> payload) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_sumDurationsFunctionName).call<dynamic>(payload);
    return result.data;
  }

  Future<Object?> _callRegisterFromFirebase(
    Map<String, Object?> payload,
  ) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_registerTrainingFunctionName).call<dynamic>(payload);
    return result.data;
  }
}
