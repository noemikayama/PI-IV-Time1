// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do enriquecimento das referências de cavalos com a URL
// da foto retornada por getHorseProfile.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos cenários de mapeamento e atualização do perfil.
//
// Data: 04/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão do teste de envio dos campos editáveis e do mapeamento da
// resposta de atualização do perfil.
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação da cobertura do mapeamento do perfil.
//
// Data: 28/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes do mapeamento do perfil do responsável, das
// responsabilidades sobre cavalos e dos valores padrão.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/profile/data/repositories/guardian_profile_repository.dart';

void main() {
  // --- Mapeamento da consulta ------------------------------------------------
  // Garante que campos válidos e responsabilidades sejam convertidos para os
  // textos consumidos pela interface.
  test('maps guardian profile fields and responsibilities', () {
    final guardianProfile = mapGuardianProfile({
      'nome': 'Ana Silva',
      'email': 'ana@email.com',
      'cavalos': [
        {
          'nome': 'Apollo',
          'responsabilidades': ['PROPRIETARIO', 'ATLETA'],
        },
        {
          'nome': 'Luna',
          'responsabilidades': ['ATLETA'],
        },
      ],
    });

    expect(guardianProfile.name, 'Ana Silva');
    expect(guardianProfile.email, 'ana@email.com');
    expect(guardianProfile.horses, hasLength(2));
    expect(guardianProfile.horses.first.relationship, 'Proprietário e atleta');
    expect(guardianProfile.horses.last.relationship, 'Atleta');
  });

  // Confirma os valores seguros usados quando o backend omite informações.
  test('uses generic strings for missing fields and an empty horse list', () {
    final guardianProfile = mapGuardianProfile(const {});

    expect(guardianProfile.name, 'Usuário HorseLife');
    expect(guardianProfile.email, 'usuario@email.com');
    expect(guardianProfile.horses, isEmpty);
  });

  test('loads the horse image before mapping the guardian profile', () async {
    final remote = _GuardianProfileRemote(
      profile: const {
        'nome': 'Ana Silva',
        'email': 'ana@email.com',
        'cavalos': [
          {
            '_id': 'horse-1',
            'nome': 'Apollo',
            'responsabilidades': ['PROPRIETARIO'],
          },
        ],
      },
      horses: const {
        'horse-1': {
          'nome': 'Apollo',
          'responsabilidades': ['PROPRIETARIO'],
          'imagens': [
            {'url': 'https://example.com/apollo.jpg'},
          ],
        },
      },
    );

    final profile = await FirebaseGuardianProfileRepository(
      remote: remote,
    ).getGuardianProfile();

    expect(remote.loadedHorseIds, ['horse-1']);
    expect(profile.horses.single.id, 'horse-1');
    expect(profile.horses.single.imageUrl, 'https://example.com/apollo.jpg');
  });

  // --- Atualização do perfil -------------------------------------------------
  // Verifica tanto o payload normalizado quanto a conversão da confirmação.
  test('sends editable fields and maps the update response', () async {
    final remote = _GuardianProfileRemote();
    final repository = FirebaseGuardianProfileRepository(remote: remote);

    final result = await repository.updateGuardianProfile(
      firstName: '  Ana ',
      lastName: ' Silva  ',
    );

    expect(remote.updateInput, {'nome': 'Ana', 'sobrenome': 'Silva'});
    expect(result.name, 'Ana Silva');
    expect(result.updatedAt, DateTime.parse('2026-11-04T12:00:00.000Z'));
  });
}

/// Fonte remota controlada que registra o payload enviado pelo repositório.
class _GuardianProfileRemote implements GuardianProfileRemoteDataSource {
  _GuardianProfileRemote({this.profile = const {}, this.horses = const {}});

  final Object? profile;
  final Map<String, Object?> horses;
  final List<String> loadedHorseIds = [];
  Map<String, String>? updateInput;

  @override
  Future<Object?> getGuardianProfile() async => profile;

  @override
  Future<Object?> getHorse(String id) async {
    loadedHorseIds.add(id);
    return horses[id];
  }

  @override
  Future<Object?> updateGuardianProfile(Map<String, String> input) async {
    updateInput = input;
    return const {
      'nome': 'Ana Silva',
      'atualizadoEm': '2026-11-04T12:00:00.000Z',
    };
  }
}
