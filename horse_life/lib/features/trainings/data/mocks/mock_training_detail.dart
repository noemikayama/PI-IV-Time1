// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento de comentários e documentação explicativa dos
// algoritmos de matching e resolução de exercícios em MockTrainingDetail.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Correção da resolução de exercícios para prevenir lista vazia
// quando o fallback não possui nomes de exercícios; busca por título na galeria
// e preservação de exercícios mockados padrão.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do provedor de dados mockados para visualização e edição
// de treinamentos em ambiente local e testes sem dependência do Firebase.
// -----------------------------------------------------------------------------

import '../../../training_plans/data/mocks/mock_training_plan_gallery.dart';
import '../../../training_plans/data/models/training_plan_gallery_item.dart';
import '../models/training_detail_data.dart';
import '../models/training_exercise_item.dart';
import 'mock_training_exercises.dart';

/// Provedor de dados mockados para os detalhes e edição de treinamentos.
///
/// Fornece instâncias consistentes de [TrainingDetailData] para testes de widget,
/// testes unitários e visualização local da tela de detalhes de treinos sem
/// necessidade de conexão ao emulador ou serviços remotos do Firebase.
abstract final class MockTrainingDetail {
  /// Orientações padrão fornecidas quando o treinamento não possui orientações específicas.
  static const List<String> defaultGuidelines = [
    'Encerrar com 5 minutos de passo.',
    'Descansar 3 minutos entre cada exercício.',
  ];

  /// Gera um retrato completo e coerente do treinamento para testes e ambiente local.
  ///
  /// Prioriza metadados fornecidos em [initialTraining] (quando presentes),
  /// correlaciona com itens do catálogo mockado [MockTrainingPlanGallery] por código/id/título
  /// e garante que os exercícios nunca sejam retornados como lista vazia.
  static TrainingDetailData buildDefault({
    String trainingCode = '42',
    TrainingPlanGalleryItem? initialTraining,
    String? trainerId,
    bool? isOwner,
    TrainingViewerRole role = TrainingViewerRole.trainer,
  }) {
    final normalizedCode = trainingCode.trim();
    final matchedGallery = _findGalleryMatch(
      codeOrId: normalizedCode,
      fallback: initialTraining,
    );

    final resolvedExerciseNames = (matchedGallery != null &&
            matchedGallery.exerciseNames.isNotEmpty)
        ? matchedGallery.exerciseNames
        : (initialTraining != null &&
                initialTraining.exerciseNames.isNotEmpty)
            ? initialTraining.exerciseNames
            : const [
                'Aquecimento ao passo',
                'Transições trote-galope',
                'Alongamento de pescoço',
              ];

    final exercises = _resolveExercises(
      exerciseNames: resolvedExerciseNames,
      role: role,
    );

    final resolvedTitle = (initialTraining?.title.trim().isNotEmpty == true)
        ? initialTraining!.title.trim()
        : (matchedGallery?.title ?? 'Trabalho de transições');

    final resolvedDescription =
        (matchedGallery?.description?.trim().isNotEmpty == true)
            ? matchedGallery!.description!.trim()
            : (initialTraining?.description?.trim().isNotEmpty == true)
                ? initialTraining!.description!.trim()
                : 'Sessão focada em equilíbrio nas transições de andamento.';

    final resolvedDuration =
        matchedGallery != null && matchedGallery.estimatedDurationMinutes > 0
            ? matchedGallery.estimatedDurationMinutes
            : (initialTraining != null &&
                    initialTraining.estimatedDurationMinutes > 0)
                ? initialTraining.estimatedDurationMinutes
                : exercises.fold<int>(
                    0,
                    (sum, item) => sum + item.durationMinutes,
                  );

    final resolvedCode = matchedGallery != null && matchedGallery.code > 0
        ? matchedGallery.code.toString()
        : (initialTraining != null && initialTraining.code > 0)
            ? initialTraining.code.toString()
            : (normalizedCode.isNotEmpty ? normalizedCode : '42');

    return TrainingDetailData(
      code: resolvedCode,
      title: resolvedTitle,
      description: resolvedDescription,
      estimatedDurationMinutes: resolvedDuration,
      exercises: List.unmodifiable(exercises),
      guidelines: List.unmodifiable(defaultGuidelines),
      role: role,
      trainerId: trainerId ?? 'trainer-1',
      isOwner: isOwner,
    );
  }

  static TrainingPlanGalleryItem? _findGalleryMatch({
    required String codeOrId,
    TrainingPlanGalleryItem? fallback,
  }) {
    // 1. Tenta correspondência exata por código ou id na galeria mockada
    for (final item in MockTrainingPlanGallery.trainings) {
      if (item.code.toString() == codeOrId || item.id == codeOrId) {
        return (fallback != null && fallback.exerciseNames.isNotEmpty)
            ? fallback
            : item;
      }
    }

    // 2. Tenta correspondência por título
    final fallbackTitle = fallback?.title.trim().toLowerCase();
    if (fallbackTitle != null && fallbackTitle.isNotEmpty) {
      for (final item in MockTrainingPlanGallery.trainings) {
        if (item.title.trim().toLowerCase() == fallbackTitle) {
          return (fallback != null && fallback.exerciseNames.isNotEmpty)
              ? fallback
              : item;
        }
      }
    }

    return fallback;
  }

  static List<TrainingDetailExercise> _resolveExercises({
    required List<String> exerciseNames,
    required TrainingViewerRole role,
  }) {
    final result = <TrainingDetailExercise>[];

    for (var i = 0; i < exerciseNames.length; i++) {
      final targetName = exerciseNames[i].trim().toLowerCase();
      TrainingExerciseItem? found;
      for (final candidate in MockTrainingExercises.exercises) {
        if (candidate.name.trim().toLowerCase() == targetName) {
          found = candidate;
          break;
        }
      }

      if (found != null) {
        result.add(
          TrainingDetailExercise(
            code: (found.code ?? (101 + i)).toString(),
            id: found.id,
            name: found.name,
            durationMinutes: found.estimatedDurationMinutes,
            description: found.description ?? 'Execução orientada pelo treinador.',
            exerciseType:
                role == TrainingViewerRole.trainer ? found.exerciseType : null,
            horse: role == TrainingViewerRole.trainer ? found.horse : null,
          ),
        );
      } else {
        result.add(
          TrainingDetailExercise(
            code: '${101 + i}',
            name: exerciseNames[i].trim(),
            durationMinutes: 15,
            description: 'Execução orientada pelo treinador em pista.',
            exerciseType: null,
            horse: null,
          ),
        );
      }
    }

    return result;
  }
}
