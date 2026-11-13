// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do adapter Firebase para obtenção da lista de cavalos
// vinculados ao treinador via Cloud Function, seguindo o padrão adotado nos
// repositórios de autenticação e perfil.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import '../models/trainer_linked_horse.dart';
import 'trainer_linked_horse_repository.dart';

// Seam da callable para permitir injeção e verificação do contrato em testes.
typedef TrainerLinkedHorsesCall = Future<Object?> Function();

// Adapter da lista de cavalos vinculados ao treinador mantida pelo backend.
final class FirebaseTrainerLinkedHorseRepository
    implements TrainerLinkedHorseRepository {
  const FirebaseTrainerLinkedHorseRepository({
    TrainerLinkedHorsesCall? getLinkedHorses,
  }) : _getLinkedHorses = getLinkedHorses;

  static const _region = 'southamerica-east1';

  // Utiliza getTrainerProfile, já disponível no backend com o array completo
  // `cavalos`; caso seja criada uma callable dedicada futuramente, basta alterar
  // este identificador mantendo o mesmo parser.
  static const _functionName = 'getTrainerProfile';

  final TrainerLinkedHorsesCall? _getLinkedHorses;

  // Valida e normaliza a coleção retornada pela Cloud Function antes de
  // entregá-la ao seletor de cavalos da camada de apresentação.
  @override
  Future<List<TrainerLinkedHorse>> fetchLinkedHorses() async {
    final response =
        await (_getLinkedHorses ?? _getLinkedHorsesFromFirebase)();

    // Suporta tanto retorno em lista direta quanto objeto encapsulando a chave
    // `cavalos`, mantendo compatibilidade com os contratos de perfil do backend.
    final rawList = switch (response) {
      final List<Object?> list => list,
      final Map<Object?, Object?> map when map['cavalos'] is List =>
        map['cavalos'] as List<Object?>,
      _ => throw const FormatException(
        'Resposta de cavalos vinculados inválida.',
      ),
    };

    return rawList
        .map(_parseLinkedHorse)
        .where((horse) => horse.name.isNotEmpty)
        .toList(growable: false);
  }

  TrainerLinkedHorse _parseLinkedHorse(Object? item) {
    if (item is! Map) {
      throw const FormatException('Item de cavalo vinculado inválido.');
    }

    final rawName = item['nome'] ?? item['name'];
    if (rawName is! String || rawName.trim().isEmpty) {
      throw const FormatException('Nome de cavalo vinculado inválido.');
    }

    final rawId = item['id'] ?? item['_id'];
    final id = switch (rawId) {
      final String value when value.trim().isNotEmpty => value.trim(),
      final Map<Object?, Object?> oidMap when oidMap[r'$oid'] is String =>
        (oidMap[r'$oid'] as String).trim(),
      _ => rawName.trim(),
    };

    return TrainerLinkedHorse(
      id: id,
      name: rawName.trim(),
    );
  }

  Future<Object?> _getLinkedHorsesFromFirebase() async {
    // A instância do FirebaseFunctions é resolvida tardiamente após o bootstrap.
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_functionName).call<dynamic>(<String, dynamic>{});
    return result.data;
  }
}
