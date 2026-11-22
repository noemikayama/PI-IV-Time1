// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do catálogo estático mockado de exercícios para testes
// locais do fluxo de seleção de exercícios no cadastro de treinamentos.
// -----------------------------------------------------------------------------

import '../../../exercises/data/mocks/mock_trainer_linked_horses.dart';
import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import 'package:horse_life/features/trainings/data/models/training_exercise_item.dart';

/// Catálogo local utilizado para testes isolados da galeria e seleção de
/// exercícios no formulário de treinamentos.
abstract final class MockTrainingExercises {
  static final _calvino = MockTrainerLinkedHorses.linkedHorses[0];
  static final _trovao = MockTrainerLinkedHorses.linkedHorses[1];

  static final List<TrainingExerciseItem> exercises = List.unmodifiable([
    const TrainingExerciseItem(
      id: 'ex-generic-1',
      name: 'Aquecimento ao passo',
      estimatedDurationMinutes: 10,
      exerciseType: ExerciseType.generic,
    ),
    const TrainingExerciseItem(
      id: 'ex-generic-2',
      name: 'Círculos ao trote',
      estimatedDurationMinutes: 15,
      exerciseType: ExerciseType.generic,
    ),
    const TrainingExerciseItem(
      id: 'ex-generic-3',
      name: 'Alongamento de pescoço',
      estimatedDurationMinutes: 8,
      exerciseType: ExerciseType.generic,
    ),
    TrainingExerciseItem(
      id: 'ex-specific-calvino-1',
      name: 'Transições trote-galope',
      estimatedDurationMinutes: 20,
      exerciseType: ExerciseType.specific,
      horse: _calvino,
    ),
    TrainingExerciseItem(
      id: 'ex-specific-calvino-2',
      name: 'Cavaletes elevados',
      estimatedDurationMinutes: 25,
      exerciseType: ExerciseType.specific,
      horse: _calvino,
    ),
    TrainingExerciseItem(
      id: 'ex-specific-trovao-1',
      name: 'Espádua adentro',
      estimatedDurationMinutes: 18,
      exerciseType: ExerciseType.specific,
      horse: _trovao,
    ),
  ]);
}
