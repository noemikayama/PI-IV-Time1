// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Substituição da callable provisória pela função de registro da
// execução e adaptação da leitura da resposta retornada pelo backend.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do contrato injetável, da integração Firebase e das
// validações aplicadas à resposta de finalização. Integração com a callable
// registerTrainingExecution e leitura do status em registro.status.
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
typedef RegisterTrainingExecutionCallable =
    Future<dynamic> Function(Map<String, dynamic> payload);

/// Implementação que envia o formulário para `registerTrainingExecution`.
class FirebaseTrainingCompletionRepository
    implements TrainingCompletionSubmitter {
  /// Nome exportado pelo backend para registrar o formulário da execução.
  static const callableName = 'registerTrainingExecution';

  FirebaseTrainingCompletionRepository({
    FirebaseFunctions? functions,
    RegisterTrainingExecutionCallable? callable,
  }) : _callable =
           callable ??
           ((payload) async =>
               (await (functions ??
                           FirebaseFunctions.instanceFor(
                             region: 'southamerica-east1',
                           ))
                       .httpsCallable(callableName)
                       .call<dynamic>(payload))
                   .data);

  // Função efetiva isolada para que a regra de conversão seja testável.
  final RegisterTrainingExecutionCallable _callable;

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
    final record = data['registro'];
    if (record is! Map) {
      throw const FormatException('Registro da execução inválido.');
    }
    final status = record['status'];
    if (status is! String || status.isEmpty) {
      throw const FormatException('Status da finalização inválido.');
    }
    return TrainingCompletionResult(status: status);
  }
}
