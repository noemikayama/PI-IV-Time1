// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração completa da edição com updateTrainerProfile, incluindo
// nome, remoção de regiões/anexos e expansão de novas macrorregiões por UF.
//
// Data: 09/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Mapeamento da lista de certificações e de suas URLs assinadas para
// abertura individual no aplicativo.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração de getTrainerProfile e getHorse, enriquecimento dos
// cavalos e conversão defensiva da resposta remota para os modelos do perfil.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:horse_life/features/authentication/application/states/trainer_service_area.dart';
import 'package:horse_life/features/authentication/data/repositories/registration_repository.dart';
import 'package:horse_life/features/authentication/data/models/brazilian_country_region.dart';

import '../models/trainer_profile_data.dart';

/// Contrato de leitura e edição incremental do perfil autenticado.
abstract interface class TrainerProfileRepository {
  /// Obtém o perfil e resolve os resumos de cavalos em dados apresentáveis.
  Future<TrainerProfileData> getTrainerProfile();

  /// Adiciona uma abrangência sem substituir as regiões já cadastradas.
  Future<void> addServiceArea(TrainerServiceArea area);

  /// Persiste somente as diferenças reunidas pela tela de edição.
  Future<void> updateTrainerProfile(TrainerProfileUpdate update);
}

/// Diferenças aceitas pela callable de edição do perfil profissional.
class TrainerProfileUpdate {
  const TrainerProfileUpdate({
    this.firstName,
    this.lastName,
    this.serviceRegionsToAdd = const [],
    this.serviceRegionsToRemove = const [],
    this.experiencePathToRemove,
    this.certificationPathsToRemove = const [],
  });

  final String? firstName;
  final String? lastName;
  final List<TrainerProfileServiceRegion> serviceRegionsToAdd;
  final List<TrainerProfileServiceRegion> serviceRegionsToRemove;
  final String? experiencePathToRemove;
  final List<String> certificationPathsToRemove;

  bool get isEmpty =>
      firstName == null &&
      lastName == null &&
      serviceRegionsToAdd.isEmpty &&
      serviceRegionsToRemove.isEmpty &&
      experiencePathToRemove == null &&
      certificationPathsToRemove.isEmpty;

  Map<String, Object> toJson() => {
    if (firstName != null) 'nome': firstName!.trim(),
    if (lastName != null) 'sobrenome': lastName!.trim(),
    if (serviceRegionsToAdd.isNotEmpty || serviceRegionsToRemove.isNotEmpty)
      'regioesAtendimento': <String, Object>{
        if (serviceRegionsToAdd.isNotEmpty)
          'adicionar': serviceRegionsToAdd
              .map((region) => region.toJson())
              .toList(growable: false),
        if (serviceRegionsToRemove.isNotEmpty)
          'remover': serviceRegionsToRemove
              .map((region) => region.toJson())
              .toList(growable: false),
      },
    if (experiencePathToRemove != null)
      'experiencias': <String, Object>{'remover': experiencePathToRemove!},
    if (certificationPathsToRemove.isNotEmpty)
      'certificacoes': <String, Object>{'remover': certificationPathsToRemove},
  };
}

/// Carrega um cavalo pelo identificador presente no resumo do perfil.
typedef HorseProfileLoader = Future<Map<String, dynamic>> Function(String id);

/// Permite substituir a chamada de atualização em testes de contrato.
typedef TrainerProfileUpdateCall =
    Future<void> Function(Map<String, Object> data);

/// Obtém o perfil e os cavalos do treinador pela Function autenticada.
class FirebaseTrainerProfileRepository implements TrainerProfileRepository {
  FirebaseTrainerProfileRepository({
    FirebaseFunctions? functions,
    TrainerProfileUpdateCall? updateProfile,
  }) : _providedFunctions = functions,
       _updateProfile = updateProfile;

  final FirebaseFunctions? _providedFunctions;
  final TrainerProfileUpdateCall? _updateProfile;

  FirebaseFunctions get _functions =>
      _providedFunctions ??
      FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  /// Serializa a hierarquia escolhida no mesmo formato usado pelo cadastro.
  @override
  Future<void> addServiceArea(TrainerServiceArea area) async {
    await updateTrainerProfile(
      TrainerProfileUpdate(
        serviceRegionsToAdd: trainerProfileRegionsFromArea(area),
      ),
    );
  }

  @override
  Future<void> updateTrainerProfile(TrainerProfileUpdate update) async {
    if (update.isEmpty) return;
    try {
      final data = update.toJson();
      final updateProfile = _updateProfile;
      if (updateProfile != null) {
        await updateProfile(data);
      } else {
        await _functions.httpsCallable('updateTrainerProfile').call<void>(data);
      }
    } on FirebaseFunctionsException catch (error) {
      throw RegistrationFailure(
        error.message ?? 'Não foi possível salvar as alterações do perfil.',
      );
    }
  }

  @override
  Future<TrainerProfileData> getTrainerProfile() async {
    final response = await _functions
        .httpsCallable('getTrainerProfile')
        .call<dynamic>(<String, dynamic>{});
    if (response.data is! Map) {
      throw const FormatException('Resposta inválida da Cloud Function.');
    }
    final profileJson = Map<String, dynamic>.from(response.data as Map);
    final enrichedProfile = await enrichTrainerProfileHorses(profileJson, (
      id,
    ) async {
      final horseResponse = await _functions
          .httpsCallable('getHorse')
          .call<dynamic>(<String, dynamic>{'id': id});
      if (horseResponse.data is! Map) {
        throw const FormatException('Resposta de cavalo inválida.');
      }
      return Map<String, dynamic>.from(horseResponse.data as Map);
    });
    return mapTrainerProfile(enrichedProfile);
  }
}

// Macrorregiões não existem no contrato remoto. Elas são expandidas para uma
// entrada "Todas as cidades" por UF, exatamente como no cadastro inicial.
List<TrainerProfileServiceRegion> trainerProfileRegionsFromArea(
  TrainerServiceArea area,
) {
  return switch (area.type) {
    TrainerServiceAreaType.countryRegion => [
      for (final stateCode in _countryRegionStateCodes(area.countryRegion))
        TrainerProfileServiceRegion(
          state: stateCode,
          city: 'Todas as cidades',
          complement: 'Região ${area.countryRegion}',
        ),
    ],
    TrainerServiceAreaType.state => [
      TrainerProfileServiceRegion(
        state: area.stateCode!,
        city: 'Todas as cidades',
        complement: 'Estado inteiro',
      ),
    ],
    TrainerServiceAreaType.city => [
      TrainerProfileServiceRegion(state: area.stateCode!, city: area.cityName!),
    ],
  };
}

List<String> _countryRegionStateCodes(String regionName) {
  final region = BrazilianCountryRegions.values.where(
    (region) => region.name == regionName,
  );
  if (region.isEmpty) return const [];
  final stateCodes = region.single.stateCodes.toList()..sort();
  return stateCodes;
}

/// Completa as referências do perfil com os dados e URLs que `getHorse`
/// já fornece, sem exigir qualquer alteração no backend.
Future<Map<String, dynamic>> enrichTrainerProfileHorses(
  Map<String, dynamic> profile,
  HorseProfileLoader loadHorse,
) async {
  final references = _asList(profile['cavalos']).map(_asMap).toList();
  final horses = await Future.wait(
    references.map((reference) async {
      final id = _horseId(reference);
      if (id == null) return reference;
      return loadHorse(id);
    }),
  );
  return <String, dynamic>{...profile, 'cavalos': horses};
}

/// Converte o JSON das callables em valores seguros para a apresentação.
///
/// Campos ausentes recebem fallbacks para que dados antigos ou incompletos não
/// quebrem a tela; documentos sem URL não são expostos como disponíveis.
TrainerProfileData mapTrainerProfile(Map<String, dynamic> json) {
  final experience = _asMap(json['experiencias']);
  final certifications = _asList(json['certificacoes']);
  final regionEntries = _asList(json['regioesAtendimento'])
      .map(_asMap)
      .map(_mapRegion)
      .whereType<TrainerProfileServiceRegion>()
      .toList(growable: false);
  final horses = _asList(json['cavalos'])
      .map(_asMap)
      .map(
        (horse) => TrainerProfileHorse(
          name: _withFallback(horse['nome'], 'Cavalo sem nome'),
          imageUrl: _firstImageUrl(horse['imagens']),
        ),
      )
      .toList(growable: false);

  return TrainerProfileData(
    name: _withFallback(json['nome'], 'Usuário HorseLife'),
    email: _withFallback(json['email'], 'usuario@email.com'),
    professionalStatus: _professionalStatus(json['situacaoProfissional']),
    experience: _mapExperience(experience),
    certificationCount: certifications.length,
    certifications: certifications
        .map(_asMap)
        .map(_mapDocument)
        .whereType<TrainerExperienceDocument>()
        .toList(growable: false),
    serviceRegions: regionEntries.map((region) => region.label).toList(),
    serviceRegionEntries: regionEntries,
    horses: horses,
  );
}

TrainerExperienceDocument? _mapExperience(Map<String, dynamic> json) {
  return _mapDocument(json, fallbackName: 'experiencia_profissional.pdf');
}

TrainerExperienceDocument? _mapDocument(
  Map<String, dynamic> json, {
  String fallbackName = 'certificacao.pdf',
}) {
  final url = _asText(json['url']).trim();
  if (url.isEmpty) return null;

  final path = _asText(json['caminho']).trim();
  final pathParts = path.split('/').where((part) => part.isNotEmpty).toList();
  final rawName = pathParts.isEmpty ? null : pathParts.last;
  final decodedName = rawName == null ? '' : Uri.decodeComponent(rawName);
  return TrainerExperienceDocument(
    fileName: decodedName.isEmpty ? fallbackName : decodedName,
    url: url,
    path: path,
  );
}

String _professionalStatus(dynamic value) => switch (_asText(value)) {
  'DISPONIVEL' => 'Disponível',
  'AFASTADO' => 'Afastado',
  'INDISPONIVEL' => 'Indisponível',
  'INATIVO' => 'Inativo',
  _ => 'Situação não informada',
};

TrainerProfileServiceRegion? _mapRegion(Map<String, dynamic> region) {
  final city = _asText(region['cidade']).trim();
  final state = _asText(region['estado']).trim();
  final complement = _asText(region['complemento']).trim();
  if (city.isEmpty && state.isEmpty) return null;
  return TrainerProfileServiceRegion(
    state: state,
    city: city,
    complement: complement.isEmpty ? null : complement,
  );
}

String? _firstImageUrl(dynamic value) {
  for (final item in _asList(value)) {
    final url = _asText(_asMap(item)['url']).trim();
    if (url.isNotEmpty) return url;
  }
  return null;
}

String? _horseId(Map<String, dynamic> horse) {
  final value = horse['id'] ?? horse['_id'];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is Map) {
    final oid = _asText(value[r'$oid']).trim();
    if (oid.isNotEmpty) return oid;
  }
  return null;
}

String _withFallback(dynamic value, String fallback) {
  final text = _asText(value).trim();
  return text.isEmpty ? fallback : text;
}

String _asText(dynamic value) => value is String ? value : '';
List<dynamic> _asList(dynamic value) => value is List ? value : const [];
Map<String, dynamic> _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
