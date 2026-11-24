// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Inclusão de códigos sequenciais e descrições nos exercícios mockados.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do catálogo estático mockado de exercícios para testes
// locais do fluxo de seleção de exercícios no cadastro de treinamentos.
// -----------------------------------------------------------------------------

import '../../../exercises/data/mocks/mock_trainer_linked_horses.dart';
import '../../../exercises/data/models/exercise_type.dart';
import '../models/training_exercise_item.dart';

/// Catálogo local utilizado para testes isolados da galeria e seleção de
/// exercícios no formulário de treinamentos.
abstract final class MockTrainingExercises {
  static final _calvino = MockTrainerLinkedHorses.linkedHorses[0];
  static final _trovao = MockTrainerLinkedHorses.linkedHorses[1];

  static final List<TrainingExerciseItem> exercises = List.unmodifiable([
    const TrainingExerciseItem(
      id: 'ex-generic-1',
      code: 101,
      name: 'Aquecimento ao passo',
      description: 'Caminhada em pista para aquecimento muscular e soltura inicial.',
      estimatedDurationMinutes: 10,
      exerciseType: ExerciseType.generic,
    ),
    const TrainingExerciseItem(
      id: 'ex-generic-2',
      code: 102,
      name: 'Círculos ao trote',
      description: 'Círculos amplos alternando mãos para equilíbrio e flexão.',
      estimatedDurationMinutes: 15,
      exerciseType: ExerciseType.generic,
    ),
    const TrainingExerciseItem(
      id: 'ex-generic-3',
      code: 103,
      name: 'Alongamento de pescoço',
      description: 'Trabalho em extensão cervical mantendo cadência constante.',
      estimatedDurationMinutes: 8,
      exerciseType: ExerciseType.generic,
    ),
    TrainingExerciseItem(
      id: 'ex-specific-calvino-1',
      code: 104,
      name: 'Transições trote-galope',
      description: 'Alternância controlada entre trote e galope com resposta rápida.',
      estimatedDurationMinutes: 20,
      exerciseType: ExerciseType.specific,
      horse: _calvino,
    ),
    TrainingExerciseItem(
      id: 'ex-specific-calvino-2',
      code: 105,
      name: 'Cavaletes elevados',
      description: 'Passagem por sequência de cavaletes ajustados para elevação.',
      estimatedDurationMinutes: 25,
      exerciseType: ExerciseType.specific,
      horse: _calvino,
    ),
    TrainingExerciseItem(
      id: 'ex-specific-trovao-1',
      code: 106,
      name: 'Espádua adentro',
      description: 'Deslocamento lateral em pista mantendo encurvamento uniforme.',
      estimatedDurationMinutes: 18,
      exerciseType: ExerciseType.specific,
      horse: _trovao,
    ),
  ]);
}
