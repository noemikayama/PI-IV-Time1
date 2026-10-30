// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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

  test('uses generic strings for missing fields and an empty horse list', () {
    final guardianProfile = mapGuardianProfile(const {});

    expect(guardianProfile.name, 'Usuário HorseLife');
    expect(guardianProfile.email, 'usuario@email.com');
    expect(guardianProfile.horses, isEmpty);
  });
}
