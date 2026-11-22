// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do catálogo estático mockado de cavalos vinculados ao
// treinador para viabilizar testes do fluxo de exercícios específicos enquanto
// a Cloud Function e os vínculos no banco de dados não estão disponíveis.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';

// Catálogo estático de animais vinculados utilizado para testes locais do
// fluxo de prescrição de exercícios específicos (8 etapas).
abstract final class MockTrainerLinkedHorses {
  static const List<TrainerLinkedHorse> linkedHorses = [
    TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino'),
    TrainerLinkedHorse(id: 'horse-trovao', name: 'Trovão'),
  ];

  static const List<TrainerLinkedHorse> empty = [];
}
