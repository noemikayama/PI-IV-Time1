// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do contrato de carregamento, da callable injetável e
// da formação do payload semanal enviado ao backend.
//
// Data: 20/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do contrato de carregamento da agenda e do repositório
// Firebase que consulta a callable getTrainingAgenda por semana.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';

/// Porta de leitura da agenda usada pela apresentação.
///
/// Sem [date], carrega a semana definida pelo backend. Com uma data, solicita
/// a semana que contém aquele dia.
abstract interface class TrainingAgendaLoader {
  Future<TrainingAgendaData> fetchAgenda({DateTime? date});
}

/// Assinatura injetável da callable, usada para isolar o Firebase nos testes.
typedef TrainingAgendaCallable =
    Future<dynamic> Function(Map<String, dynamic> payload);

/// Integração autenticada com `getTrainingAgenda` em `southamerica-east1`.
class FirebaseTrainingAgendaRepository implements TrainingAgendaLoader {
  FirebaseTrainingAgendaRepository({
    FirebaseFunctions? functions,
    TrainingAgendaCallable? callable,
  }) : _callable =
           callable ??
           ((payload) async =>
               (await (functions ??
                           FirebaseFunctions.instanceFor(
                             region: 'southamerica-east1',
                           ))
                       .httpsCallable('getTrainingAgenda')
                       .call<dynamic>(payload))
                   .data);

  final TrainingAgendaCallable _callable;

  /// Consulta a semana solicitada e converte a resposta para o domínio visual.
  ///
  /// A data é omitida na carga inicial. Respostas que não sejam mapas são
  /// rejeitadas antes da conversão detalhada feita por [TrainingAgendaData].
  @override
  Future<TrainingAgendaData> fetchAgenda({DateTime? date}) async {
    final payload = <String, dynamic>{};
    if (date != null) payload['data'] = _formatDate(date);
    final response = await _callable(payload);
    if (response is! Map) {
      throw const FormatException('Resposta inválida da agenda.');
    }
    return TrainingAgendaData.fromJson(Map<String, dynamic>.from(response));
  }
}

// Serializa somente a parte civil da data exigida pelo contrato HTTP.
String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
