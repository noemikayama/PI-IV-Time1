// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Enriquecimento dos cavalos vinculados com os dados de getHorseProfile
// para disponibilizar a foto real nos cards do perfil do responsável.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação das fronteiras de domínio, adaptador de Functions,
// mapeamento e persistência do perfil do responsável.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Mapeamento do identificador do cavalo vinculado.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Mapeamento da primeira URL de imagem válida retornada para cada
// cavalo vinculado ao perfil do responsável.
// Alteração: Documentação dos contratos, integração remota, validação das
// respostas e conversão dos dados do perfil.
//
// Data: 04/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão da atualização do perfil e separação da fonte remota do
// Firebase para permitir injeção, validação e testes do repositório.
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
  /// Carrega os dados usados na visualização do perfil.
  Future<GuardianProfileData> getGuardianProfile();

  /// Persiste apenas os campos de nome permitidos pelo contrato atual.
  Future<GuardianProfileUpdate> updateGuardianProfile({
    required String firstName,
    required String lastName,
  });
}

/// Fronteira remota que mantém o SDK do Firebase fora do repositório testável.
abstract interface class GuardianProfileRemoteDataSource {
  /// Retorna a resposta bruta da callable de consulta.
  Future<Object?> getGuardianProfile();

  /// Retorna os dados completos de um cavalo vinculado ao perfil.
  Future<Object?> getHorse(String id);

  /// Retorna a resposta bruta da callable de atualização.
  Future<Object?> updateGuardianProfile(Map<String, String> input);
}

/// Implementação remota das callables de perfil.
final class FirebaseGuardianProfileRemoteDataSource
    implements GuardianProfileRemoteDataSource {
  const FirebaseGuardianProfileRemoteDataSource();

  // A instância regional é obtida somente quando uma operação é executada.
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  @override
  Future<Object?> getGuardianProfile() async {
    final response = await _functions
        .httpsCallable('getGuardianProfile')
        .call<Object?>(const <String, dynamic>{});
    return response.data;
  }

  @override
  Future<Object?> getHorse(String id) async {
    final response = await _functions
        .httpsCallable('getHorseProfile')
        .call<Object?>(<String, dynamic>{'id': id});
    return response.data;
  }

  @override
  Future<Object?> updateGuardianProfile(Map<String, String> input) async {
    final response = await _functions
        .httpsCallable('updateGuardianProfile')
        .call<Object?>(input);
    return response.data;
  }
}

/// Obtém e atualiza o perfil pelas Cloud Functions.
class FirebaseGuardianProfileRepository implements GuardianProfileRepository {
  const FirebaseGuardianProfileRepository({
    GuardianProfileRemoteDataSource remote =
        const FirebaseGuardianProfileRemoteDataSource(),
  }) : _remote = remote;

  final GuardianProfileRemoteDataSource _remote;

  // --- Consulta e conversão do perfil ---------------------------------------
  @override
  Future<GuardianProfileData> getGuardianProfile() async {
    final response = await _remote.getGuardianProfile();
    if (response is! Map) {
      throw const FormatException('Resposta inválida da Cloud Function.');
    }
    final profile = Map<String, dynamic>.from(response);
    final enrichedProfile = await enrichGuardianProfileHorses(profile, (
      id,
    ) async {
      final horse = await _remote.getHorse(id);
      if (horse is! Map) {
        throw const FormatException('Resposta de cavalo inválida.');
      }
      return Map<String, dynamic>.from(horse);
    });
    return mapGuardianProfile(enrichedProfile);
  }

  // --- Atualização e validação da resposta ----------------------------------
  @override
  Future<GuardianProfileUpdate> updateGuardianProfile({
    required String firstName,
    required String lastName,
  }) async {
    final response = await _remote.updateGuardianProfile({
      // Remove espaços externos antes de cruzar a fronteira da aplicação.
      'nome': firstName.trim(),
      'sobrenome': lastName.trim(),
    });
    if (response is! Map) {
      throw const FormatException('Resposta inválida da Cloud Function.');
    }
    // A atualização só é considerada válida quando os dois campos de
    // confirmação esperados podem ser convertidos com segurança.
    final data = Map<String, dynamic>.from(response);
    final name = _asText(data['nome']).trim();
    final updatedAt = DateTime.tryParse(_asText(data['atualizadoEm']));
    if (name.isEmpty || updatedAt == null) {
      throw const FormatException('Resposta inválida da Cloud Function.');
    }
    return GuardianProfileUpdate(name: name, updatedAt: updatedAt);
  }
}

/// Carrega os dados completos dos cavalos resumidos pelo perfil.
///
/// Referências sem identificador são preservadas para que um registro antigo
/// não impeça a exibição dos demais vínculos válidos.
Future<Map<String, dynamic>> enrichGuardianProfileHorses(
  Map<String, dynamic> profile,
  Future<Map<String, dynamic>> Function(String id) loadHorse,
) async {
  final references = _asList(profile['cavalos']).map(_asMap).toList();
  final horses = await Future.wait(
    references.map((reference) async {
      final id = _horseId(reference);
      if (id.isEmpty) return reference;
      final horse = await loadHorse(id);
      return <String, dynamic>{...reference, ...horse, 'id': id};
    }),
  );
  return <String, dynamic>{...profile, 'cavalos': horses};
}

/// Converte a resposta da API em dados seguros para apresentação.
GuardianProfileData mapGuardianProfile(Map<String, dynamic> json) {
  // --- Conversão dos cavalos vinculados -------------------------------------
  final horses = _asList(json['cavalos'])
      .map((item) {
        final horse = _asMap(item);
        final responsibilities = _asList(horse['responsabilidades'])
            .map(_asText)
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
        return GuardianProfileHorse(
          id: _horseId(horse),
          name: _withFallback(horse['nome'], 'Cavalo sem nome'),
          relationship: _guardianRelationship(responsibilities),
          imageUrl: _firstImageUrl(horse['imagens']),
        );
      })
      .toList(growable: false);

  // --- Conversão dos dados principais --------------------------------------
  return GuardianProfileData(
    name: _withFallback(json['nome'], 'Usuário HorseLife'),
    email: _withFallback(json['email'], 'usuario@email.com'),
    horses: horses,
  );
}

String? _firstImageUrl(dynamic value) {
  for (final item in _asList(value)) {
    final url = _asText(_asMap(item)['url']).trim();
    if (url.isNotEmpty) return url;
  }
  return null;
}

String _horseId(Map<String, dynamic> horse) {
  final direct = _asText(horse['id'] ?? horse['_id']).trim();
  if (direct.isNotEmpty) return direct;
  return _asText(_asMap(horse['_id'])[r'$oid']).trim();
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
