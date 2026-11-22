// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Integração do repositório local com o catálogo estático
// MockTrainerLinkedHorses para testes do cadastro de exercícios específicos.
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do contrato assíncrono para consulta dos cavalos
// vinculados ao treinador e da implementação local de fallback para usos
// isolados e testes de apresentação.
// -----------------------------------------------------------------------------

import '../mocks/mock_trainer_linked_horses.dart';
import '../models/trainer_linked_horse.dart';

// Abstrai a origem dos cavalos vinculados ao treinador para que a camada de
// apresentação não dependa diretamente de detalhes da Firebase Function.
abstract interface class TrainerLinkedHorseRepository {
  Future<List<TrainerLinkedHorse>> fetchLinkedHorses();
}

// Fonte estática local usada para testar o fluxo de exercícios específicos
// enquanto a Firebase Function correspondente não está publicada.
class LocalTrainerLinkedHorseRepository
    implements TrainerLinkedHorseRepository {
  const LocalTrainerLinkedHorseRepository({
    this.horses = defaultHorses,
  });

  // Catálogo estático padrão coerente com a prototipação das telas.
  static const defaultHorses = MockTrainerLinkedHorses.linkedHorses;

  final List<TrainerLinkedHorse> horses;

  @override
  Future<List<TrainerLinkedHorse>> fetchLinkedHorses() async {
    return horses;
  }
}
