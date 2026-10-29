// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos e segmentos do código de autenticação,
// detalhando responsabilidades, fluxo de dados e integração entre camadas.
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração das modalidades profissionais com a callable
// pública getModalities.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import 'training_sport_repository.dart';

typedef TrainingSportsCall = Future<Object?> Function();

// Adapter da lista de modalidades mantida pelo backend.
final class FirebaseTrainingSportRepository implements TrainingSportRepository {
  const FirebaseTrainingSportRepository({TrainingSportsCall? getModalities})
    : _getModalities = getModalities;

  static const _region = 'southamerica-east1';
  static const _functionName = 'getModalities';

  final TrainingSportsCall? _getModalities;

  // Valida toda a coleção antes de entregá-la ao dropdown profissional.
  @override
  Future<List<String>> fetchSports() async {
    final response = await (_getModalities ?? _getModalitiesFromFirebase)();
    if (response is! List) {
      throw const FormatException('Resposta de modalidades inválida.');
    }

    return response
        .map((item) {
          if (item is! Map || item['nome'] is! String) {
            throw const FormatException('Modalidade inválida.');
          }
          return (item['nome'] as String).trim();
        })
        .toList(growable: false);
  }

  Future<Object?> _getModalitiesFromFirebase() async {
    // A callable é pública porque esta etapa ocorre antes da criação da conta.
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_functionName).call();
    return result.data;
  }
}
