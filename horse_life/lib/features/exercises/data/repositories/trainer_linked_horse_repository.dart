// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Separa implementações de teste do contrato de produção.
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

import '../models/trainer_linked_horse.dart';

// Abstrai a origem dos cavalos vinculados ao treinador para que a camada de
// apresentação não dependa diretamente de detalhes da Firebase Function.
abstract interface class TrainerLinkedHorseRepository {
  Future<List<TrainerLinkedHorse>> fetchLinkedHorses();
}
