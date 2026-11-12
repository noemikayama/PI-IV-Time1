// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura dos payloads de inclusão de cidade e da expansão de
// macrorregião, além da edição conjunta de nome, regiões e anexos.
//
// Data: 09/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do mapeamento da coleção de certificações e de suas URLs.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do mapeamento do perfil, fallbacks e enriquecimento das
// referências de cavalos com os dados retornados por getHorse.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/authentication/application/states/trainer_service_area.dart';
import 'package:horse_life/features/profile/data/models/trainer_profile_data.dart';
import 'package:horse_life/features/profile/data/repositories/trainer_profile_repository.dart';

void main() {
  test('maps trainer profile, regions and signed horse image URLs', () {
    final profile = mapTrainerProfile({
      'nome': 'Ana Souza',
      'email': 'ana@email.com',
      'situacaoProfissional': 'DISPONIVEL',
      'experiencias': {
        'caminho': '/arquivos/treinadores/1/curriculo_ana.pdf',
        'url': 'https://storage/experiencia.pdf',
      },
      'certificacoes': [
        {
          'caminho': '/arquivos/treinadores/1/certificado_salto.pdf',
          'url': 'https://storage/certificacao.pdf',
        },
      ],
      'regioesAtendimento': [
        {'cidade': 'Campinas', 'estado': 'SP'},
      ],
      'cavalos': [
        {
          'nome': 'Apollo',
          'imagens': [
            {
              'caminho': '/imagens/cavalos/1/imagem_1.jpg',
              'url': 'https://storage/apollo.jpg',
            },
          ],
        },
        {'nome': 'Luna', 'imagens': []},
      ],
    });

    expect(profile.name, 'Ana Souza');
    expect(profile.professionalStatus, 'Disponível');
    expect(profile.hasExperience, isTrue);
    expect(profile.experience?.fileName, 'curriculo_ana.pdf');
    expect(profile.experience?.url, 'https://storage/experiencia.pdf');
    expect(
      profile.experience?.path,
      '/arquivos/treinadores/1/curriculo_ana.pdf',
    );
    expect(profile.certificationCount, 1);
    expect(profile.certifications.single.fileName, 'certificado_salto.pdf');
    expect(
      profile.certifications.single.url,
      'https://storage/certificacao.pdf',
    );
    expect(profile.serviceRegions, ['Campinas - SP']);
    expect(profile.serviceRegionEntries.single.state, 'SP');
    expect(profile.serviceRegionEntries.single.city, 'Campinas');
    expect(profile.horses, hasLength(2));
    expect(profile.horses.first.imageUrl, 'https://storage/apollo.jpg');
    expect(profile.horses.last.imageUrl, isNull);
  });

  test('uses safe fallbacks for incomplete trainer data', () {
    final profile = mapTrainerProfile(const {});

    expect(profile.name, 'Usuário HorseLife');
    expect(profile.email, 'usuario@email.com');
    expect(profile.professionalStatus, 'Situação não informada');
    expect(profile.horses, isEmpty);
  });

  test('loads each horse through the existing getHorse contract', () async {
    final requestedIds = <String>[];
    final enriched = await enrichTrainerProfileHorses(
      {
        'nome': 'Ana',
        'cavalos': [
          {'_id': '507f1f77bcf86cd799439011', 'nome': 'Nome resumido'},
        ],
      },
      (id) async {
        requestedIds.add(id);
        return {
          'id': id,
          'nome': 'Apollo',
          'imagens': [
            {'url': 'https://storage/apollo.jpg'},
          ],
        };
      },
    );

    final profile = mapTrainerProfile(enriched);
    expect(requestedIds, ['507f1f77bcf86cd799439011']);
    expect(profile.horses.single.name, 'Apollo');
    expect(profile.horses.single.imageUrl, 'https://storage/apollo.jpg');
  });

  test('adds a city through the existing profile update contract', () async {
    Map<String, Object>? receivedData;
    final repository = FirebaseTrainerProfileRepository(
      updateProfile: (data) async => receivedData = data,
    );

    await repository.addServiceArea(
      const TrainerServiceArea.city(
        countryRegion: 'Sudeste',
        stateCode: 'SP',
        stateName: 'São Paulo',
        cityName: 'Campinas',
      ),
    );

    expect(receivedData, {
      'regioesAtendimento': {
        'adicionar': [
          {'estado': 'SP', 'cidade': 'Campinas'},
        ],
      },
    });
  });

  test('expands a country region using the registration format', () async {
    Map<String, Object>? receivedData;
    final repository = FirebaseTrainerProfileRepository(
      updateProfile: (data) async => receivedData = data,
    );

    await repository.addServiceArea(
      const TrainerServiceArea.countryRegion(countryRegion: 'Sudeste'),
    );

    final changes = receivedData?['regioesAtendimento'] as Map;
    final additions = changes['adicionar'] as List;
    expect(additions, hasLength(4));
    expect(additions.first, {
      'estado': 'ES',
      'cidade': 'Todas as cidades',
      'complemento': 'Região Sudeste',
    });
  });

  test('sends all editable differences using the existing contract', () async {
    Map<String, Object>? receivedData;
    final repository = FirebaseTrainerProfileRepository(
      updateProfile: (data) async => receivedData = data,
    );

    await repository.updateTrainerProfile(
      const TrainerProfileUpdate(
        firstName: 'Ana',
        lastName: 'Silva',
        serviceRegionsToAdd: [
          TrainerProfileServiceRegion(state: 'MG', city: 'Uberaba'),
        ],
        serviceRegionsToRemove: [
          TrainerProfileServiceRegion(state: 'SP', city: 'Campinas'),
        ],
        experiencePathToRemove: '/arquivos/treinadores/1/experiencia_1.pdf',
        certificationPathsToRemove: [
          '/arquivos/treinadores/1/certificacao_2.pdf',
        ],
      ),
    );

    expect(receivedData, {
      'nome': 'Ana',
      'sobrenome': 'Silva',
      'regioesAtendimento': {
        'adicionar': [
          {'estado': 'MG', 'cidade': 'Uberaba'},
        ],
        'remover': [
          {'estado': 'SP', 'cidade': 'Campinas'},
        ],
      },
      'experiencias': {'remover': '/arquivos/treinadores/1/experiencia_1.pdf'},
      'certificacoes': {
        'remover': ['/arquivos/treinadores/1/certificacao_2.pdf'],
      },
    });
  });
}
