// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura do mapeamento e validação de erros da callable de
// cavalos vinculados ao treinador.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/exercises/data/repositories/firebase_trainer_linked_horse_repository.dart';

void main() {
  test('maps a direct list of horse objects to TrainerLinkedHorse models', () async {
    final repository = FirebaseTrainerLinkedHorseRepository(
      getLinkedHorses: () async => [
        {'id': 'horse-1', 'nome': ' Calvino '},
        {'_id': r'horse-2', 'nome': 'Trovão'},
      ],
    );

    expect(
      await repository.fetchLinkedHorses(),
      const [
        TrainerLinkedHorse(id: 'horse-1', name: 'Calvino'),
        TrainerLinkedHorse(id: 'horse-2', name: 'Trovão'),
      ],
    );
  });

  test('maps a profile-style payload containing cavalos list', () async {
    final repository = FirebaseTrainerLinkedHorseRepository(
      getLinkedHorses: () async => {
        'cavalos': [
          {
            '_id': {r'$oid': 'oid-calvino'},
            'nome': 'Calvino',
          },
        ],
      },
    );

    expect(
      await repository.fetchLinkedHorses(),
      const [TrainerLinkedHorse(id: 'oid-calvino', name: 'Calvino')],
    );
  });

  test('rejects an invalid callable response', () async {
    final repository = FirebaseTrainerLinkedHorseRepository(
      getLinkedHorses: () async => {'invalido': true},
    );

    await expectLater(repository.fetchLinkedHorses(), throwsFormatException);
  });
}
