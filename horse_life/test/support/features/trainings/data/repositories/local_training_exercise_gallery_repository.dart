// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do contrato do repositório da galeria de exercícios do
// treinador e implementação local para testes de apresentação e fluxo.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/exercises/data/models/exercise_type.dart';
import '../mocks/mock_training_exercises.dart';
import 'package:horse_life/features/trainings/data/models/training_exercise_item.dart';
import 'package:horse_life/features/trainings/data/repositories/training_exercise_gallery_repository.dart';

/// Implementação local em memória utilizada em testes de widget e estados isolados.
class LocalTrainingExerciseGalleryRepository
    implements TrainingExerciseGalleryRepository {
  const LocalTrainingExerciseGalleryRepository({
    this.exercises,
  });

  final List<TrainingExerciseItem>? exercises;

  @override
  Future<List<TrainingExerciseItem>> fetchGalleryExercises({
    String? searchQuery,
    String? horseId,
  }) async {
    final source = exercises ?? MockTrainingExercises.exercises;
    final trimmedHorseId = horseId?.trim() ?? '';
    final normalizedSearch = normalizeSearchText(searchQuery ?? '');

    final filtered = source.where((exercise) {
      if (trimmedHorseId.isEmpty) {
        if (exercise.exerciseType != ExerciseType.generic) return false;
      } else {
        if (exercise.exerciseType != ExerciseType.specific ||
            exercise.horse?.id != trimmedHorseId) {
          return false;
        }
      }

      if (normalizedSearch.isNotEmpty) {
        final normalizedName = normalizeSearchText(exercise.name);
        if (!normalizedName.contains(normalizedSearch)) return false;
      }

      return true;
    }).toList();

    filtered.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return List.unmodifiable(filtered);
  }
}
