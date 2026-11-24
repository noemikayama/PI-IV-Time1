// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação dos modelos de domínio para a
// visualização e edição de treinamentos.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos modelos imutáveis de visualização, permissões e
// atualização do treinamento (TrainingViewerRole, TrainingDetailExercise,
// TrainingDetailData e TrainingUpdate).
// -----------------------------------------------------------------------------

import '../../../exercises/data/models/exercise_type.dart';
import '../../../exercises/data/models/trainer_linked_horse.dart';
import 'training_exercise_item.dart';

/// Perfil do usuário autenticado retornado por `getTrainingDetails`.
///
/// Define as regras de exibição na tela: treinadores proprietários visualizam e
/// podem editar o treinamento, enquanto responsáveis têm acesso exclusivamente consultivo.
enum TrainingViewerRole {
  trainer(apiKey: 'treinador'),
  guardian(apiKey: 'responsavel');

  const TrainingViewerRole({required this.apiKey});

  final String apiKey;

  /// Converte a string de cargo do backend para o enum correspondente.
  static TrainingViewerRole fromApi(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'treinador' || 'trainer' => TrainingViewerRole.trainer,
      'responsavel' || 'responsável' || 'guardian' => TrainingViewerRole.guardian,
      _ => TrainingViewerRole.guardian,
    };
  }
}

/// Representação detalhada de um exercício exibido nos detalhes do treinamento.
final class TrainingDetailExercise {
  const TrainingDetailExercise({
    required this.code,
    required this.name,
    required this.durationMinutes,
    required this.description,
    this.id,
    this.exerciseType,
    this.horse,
  });

  /// Constrói um exercício de detalhe a partir de um item selecionado da
  /// galeria ou criado na sessão durante a edição do treinamento.
  factory TrainingDetailExercise.fromExerciseItem(TrainingExerciseItem item) {
    final numericCode = item.code != null && item.code! > 0
        ? item.code.toString()
        : item.id.trim();

    return TrainingDetailExercise(
      code: numericCode,
      id: item.id.trim().isNotEmpty ? item.id.trim() : null,
      name: item.name.trim(),
      durationMinutes: item.estimatedDurationMinutes,
      description: item.description?.trim() ?? '',
      exerciseType: item.exerciseType,
      horse: item.horse,
    );
  }

  final String code;
  final String? id;
  final String name;
  final int durationMinutes;
  final String description;
  final ExerciseType? exerciseType;
  final TrainerLinkedHorse? horse;

  String get formattedDuration => '$durationMinutes min';

  String get displayDescription =>
      description.trim().isNotEmpty ? description.trim() : 'Não informada';

  /// Converte este exercício de detalhe para [TrainingExerciseItem], usado nos
  /// cards de edição e na galeria de seleção múltipla.
  TrainingExerciseItem toExerciseItem() {
    final trimmedId = id?.trim() ?? '';
    final trimmedCode = code.trim();
    return TrainingExerciseItem(
      id: trimmedId.isNotEmpty ? trimmedId : trimmedCode,
      name: name,
      estimatedDurationMinutes: durationMinutes,
      exerciseType: exerciseType ?? ExerciseType.generic,
      horse: horse,
      code: int.tryParse(trimmedCode),
      description: description.trim().isEmpty ? null : description.trim(),
    );
  }
}

/// Retrato completo do treinamento exibido em `TrainingDetailScreen`.
final class TrainingDetailData {
  const TrainingDetailData({
    required this.code,
    required this.title,
    required this.description,
    required this.estimatedDurationMinutes,
    required this.exercises,
    required this.guidelines,
    required this.role,
    this.trainerId,
    this.isOwner,
  });

  final String code;
  final String title;
  final String description;
  final int estimatedDurationMinutes;
  final List<TrainingDetailExercise> exercises;
  final List<String> guidelines;
  final TrainingViewerRole role;
  final String? trainerId;
  final bool? isOwner;

  String get formattedDuration => '$estimatedDurationMinutes min';

  String get displayDescription =>
      description.trim().isNotEmpty ? description.trim() : 'Não informada';

  /// Define se o usuário atual possui permissão para editar este treinamento.
  bool canManage({String? currentUserId, required bool isTrainer}) {
    if (!isTrainer || role == TrainingViewerRole.guardian) return false;
    if (isOwner != null) return isOwner!;

    final normalizedTrainerId = trainerId?.trim() ?? '';
    final normalizedCurrentUserId = currentUserId?.trim() ?? '';
    if (normalizedTrainerId.isNotEmpty && normalizedCurrentUserId.isNotEmpty) {
      return normalizedCurrentUserId == normalizedTrainerId;
    }
    return true;
  }

  TrainingDetailData copyWith({
    String? code,
    String? title,
    String? description,
    int? estimatedDurationMinutes,
    List<TrainingDetailExercise>? exercises,
    List<String>? guidelines,
    TrainingViewerRole? role,
    String? trainerId,
    bool? isOwner,
  }) {
    return TrainingDetailData(
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      exercises: exercises != null
          ? List.unmodifiable(exercises)
          : this.exercises,
      guidelines: guidelines != null
          ? List.unmodifiable(guidelines)
          : this.guidelines,
      role: role ?? this.role,
      trainerId: trainerId ?? this.trainerId,
      isOwner: isOwner ?? this.isOwner,
    );
  }
}

/// Estado final consolidado pelo formulário de edição do treinamento.
final class TrainingUpdate {
  const TrainingUpdate({
    required this.title,
    required this.description,
    required this.estimatedDurationMinutes,
    required this.guidelines,
    required this.exercises,
  });

  final String title;
  final String description;
  final int estimatedDurationMinutes;
  final List<String> guidelines;
  final List<TrainingExerciseItem> exercises;

  /// Serializa os dados editados no formato esperado pela Cloud Function `updateTraining`.
  Map<String, Object?> toJson(
    String code, {
    List<String>? resolvedExerciseCodes,
  }) {
    final codes = resolvedExerciseCodes ??
        exercises
            .map(
              (exercise) => (exercise.code != null && exercise.code! > 0)
                  ? exercise.code.toString()
                  : exercise.id.trim(),
            )
            .toList(growable: false);

    return {
      'codigo': code.trim(),
      'titulo': title.trim(),
      'descricao': description.trim(),
      'duracaoEstimada': estimatedDurationMinutes,
      'orientacoes': guidelines
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      'exercicioCodigos': codes,
    };
  }

  /// Aplica as alterações editadas sobre os detalhes atuais do treinamento.
  TrainingDetailData applyTo(TrainingDetailData base) {
    return base.copyWith(
      title: title.trim(),
      description: description.trim(),
      estimatedDurationMinutes: estimatedDurationMinutes,
      guidelines: List.unmodifiable(
        guidelines.map((item) => item.trim()).where((item) => item.isNotEmpty),
      ),
      exercises: List.unmodifiable(
        exercises.map(TrainingDetailExercise.fromExerciseItem),
      ),
    );
  }
}
