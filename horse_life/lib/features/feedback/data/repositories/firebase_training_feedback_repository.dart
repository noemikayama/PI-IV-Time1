// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração das callables getTrainingRecord e registerTrainingFeedback.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import '../models/training_execution_record.dart';
import '../models/training_record_mapper.dart';
import 'training_feedback_repository.dart';

/// A injeção da callable permite testar o contrato sem inicializar Firebase.
typedef TrainingFeedbackCallable = Future<Object?> Function(
  String name, Map<String, dynamic> payload,
);

class FirebaseTrainingFeedbackRepository implements TrainingFeedbackRepository {
  FirebaseTrainingFeedbackRepository({
    FirebaseFunctions? functions,
    TrainingFeedbackCallable? callable,
  }) : _callable = callable ?? ((name, payload) async =>
          (await (functions ?? FirebaseFunctions.instanceFor(region: 'southamerica-east1'))
              .httpsCallable(name).call<dynamic>(payload)).data);

  final TrainingFeedbackCallable _callable;

  @override
  Future<TrainingExecutionRecord> findById(String recordId) async =>
      TrainingRecordMapper.fromResponse(await _callable(
        'getTrainingRecord', {'registroId': recordId},
      ));

  @override
  Future<TrainingExecutionRecord> registerFeedback({
    required String recordId,
    required TrainingExecutionFeedback feedback,
  }) async => TrainingRecordMapper.fromResponse(await _callable(
    'registerTrainingFeedback', {
      'registroId': recordId,
      'comentario': feedback.comment.trim(),
      'dificuldadesIdentificadas': feedback.difficulties,
      'orientacoes': feedback.guidelines,
    },
  ));
}
