// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do contrato injetável, da integração Firebase e das
// validações aplicadas à resposta de finalização.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do repositório de finalização, com envio do formulário à
// callable finishTraining e validação do status retornado.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';

/// Porta de saída usada pela apresentação para persistir uma conclusão.
abstract interface class TrainingCompletionSubmitter {
  Future<TrainingCompletionResult> submit(TrainingCompletionInput input);
}

/// Assinatura injetável da callable, permitindo testes sem Firebase.
typedef FinishTrainingCallable =
    Future<dynamic> Function(Map<String, dynamic> payload);

/// Implementação que envia o formulário para `finishTraining`.
class FirebaseTrainingCompletionRepository
    implements TrainingCompletionSubmitter {
  FirebaseTrainingCompletionRepository({
    FirebaseFunctions? functions,
    FinishTrainingCallable? callable,
  }) : _callable =
           callable ??
           ((payload) async =>
               (await (functions ??
                           FirebaseFunctions.instanceFor(
                             region: 'southamerica-east1',
                           ))
                       .httpsCallable('finishTraining')
                       .call<dynamic>(payload))
                   .data);

  // Função efetiva isolada para que a regra de conversão seja testável.
  final FinishTrainingCallable _callable;

  /// Serializa [input], valida a forma mínima da resposta e devolve o status
  /// persistido pelo backend.
  @override
  Future<TrainingCompletionResult> submit(TrainingCompletionInput input) async {
    final response = await _callable(input.toJson());
    if (response is! Map) {
      throw const FormatException(
        'Resposta inválida da finalização do treino.',
      );
    }
    final data = Map<String, dynamic>.from(response);
    final status = data['status'];
    if (status is! String || status.isEmpty) {
      throw const FormatException('Status da finalização inválido.');
    }
    return TrainingCompletionResult(status: status);
  }
}
