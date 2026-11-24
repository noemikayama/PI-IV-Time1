// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do mapeamento da callable de modalidades profissionais.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/authentication/data/repositories/firebase_training_sport_repository.dart';

void main() {
  test('maps modality objects to their names', () async {
    final repository = FirebaseTrainingSportRepository(
      getModalities: () async => [
        {
          'id': '1',
          'codigo': 1,
          'nome': ' Adestramento ',
          'descricao': 'Modalidade',
        },
        {'id': '2', 'codigo': 2, 'nome': 'Salto', 'descricao': 'Modalidade'},
      ],
    );

    expect(await repository.fetchSports(), ['Adestramento', 'Salto']);
  });

  test('rejects an invalid callable response', () async {
    final repository = FirebaseTrainingSportRepository(
      getModalities: () async => {'nome': 'Salto'},
    );

    await expectLater(repository.fetchSports(), throwsFormatException);
  });
}
