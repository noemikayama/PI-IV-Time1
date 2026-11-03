// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do contrato, da integração Firebase e do mapeamento.
//
// Data: 28/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do contrato e da implementação Firebase para carregar e
// converter os dados do perfil do responsável.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import '../models/guardian_profile_data.dart';

/// Contrato de acesso aos dados do perfil do responsável.
abstract interface class GuardianProfileRepository {
  Future<GuardianProfileData> getGuardianProfile();
}

/// Obtém o perfil pela Cloud Function `getGuardianProfile`.
class FirebaseGuardianProfileRepository implements GuardianProfileRepository {
  FirebaseGuardianProfileRepository({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFunctions _functions;

  @override
  Future<GuardianProfileData> getGuardianProfile() async {
    final response = await _functions
        .httpsCallable('getGuardianProfile')
        .call<dynamic>(<String, dynamic>{});
    if (response.data is! Map) {
      throw const FormatException('Resposta inválida da Cloud Function.');
    }
    return mapGuardianProfile(Map<String, dynamic>.from(response.data as Map));
  }
}

/// Converte a resposta da API em dados seguros para apresentação.
GuardianProfileData mapGuardianProfile(Map<String, dynamic> json) {
  final horses = _asList(json['cavalos'])
      .map((item) {
        final horse = _asMap(item);
        final responsibilities = _asList(horse['responsabilidades'])
            .map(_asText)
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
        return GuardianProfileHorse(
          name: _withFallback(horse['nome'], 'Cavalo sem nome'),
          relationship: _guardianRelationship(responsibilities),
        );
      })
      .toList(growable: false);

  return GuardianProfileData(
    name: _withFallback(json['nome'], 'Usuário HorseLife'),
    email: _withFallback(json['email'], 'usuario@email.com'),
    horses: horses,
  );
}

// Traduz as responsabilidades armazenadas no backend para o texto da interface.
String _guardianRelationship(List<String> responsibilities) {
  final isOwner = responsibilities.contains('PROPRIETARIO');
  final isAthlete = responsibilities.contains('ATLETA');
  if (isOwner && isAthlete) return 'Proprietário e atleta';
  if (isOwner) return 'Proprietário';
  if (isAthlete) return 'Atleta';
  return 'Responsável';
}

String _withFallback(dynamic value, String fallback) {
  final text = _asText(value).trim();
  return text.isEmpty ? fallback : text;
}

String _asText(dynamic value) => value is String ? value : '';

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

Map<String, dynamic> _asMap(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : const {};
}
