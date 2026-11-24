// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação e comentários explicativos para
// facilitar a leitura, padronização e manutenção do contrato de repositório.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da abstração ExerciseDetailRepository, exceção tipada
// ExerciseDetailFailure e implementação em memória LocalExerciseDetailRepository
// para visualização e edição de exercícios.
// -----------------------------------------------------------------------------

import '../../application/states/exercise_media.dart';
import '../models/exercise_detail_data.dart';
import '../models/exercise_type.dart';

/// Erro tipado com mensagem amigável nas operações de detalhes/edição de exercício.
///
/// Lançada tanto por validações de regras de negócio locais quanto por respostas
/// de erro mapeadas a partir das Cloud Functions do Firebase.
final class ExerciseDetailFailure implements Exception {
  const ExerciseDetailFailure(this.message);

  /// Mensagem em português adequada para exibição em snackbars ou cards de erro.
  final String message;

  @override
  String toString() => message;
}

/// Contrato abstrato de acesso e persistência de dados detalhados de exercícios.
///
/// Define as operações fundamentais para a feature de visualização e edição:
/// 1. Consulta pontual por identificador ([id] ou [code]);
/// 2. Atualização atômica de dados cadastrais e sincronização de mídias auxiliares.
abstract class ExerciseDetailRepository {
  /// Consulta os detalhes completos de um exercício pelo seu [id] (ObjectId)
  /// ou pelo seu [code] (código numérico incremental).
  ///
  /// Lança [ExerciseDetailFailure] caso o identificador não seja encontrado ou
  /// ocorra falha de comunicação com o backend.
  Future<ExerciseDetailData> getExercise({String? id, String? code});

  /// Salva as alterações cadastrais e mídias de [original] aplicando o delta [update].
  ///
  /// Retorna um [ExerciseUpdateResult] contendo a entidade atualizada e eventuais
  /// avisos de sincronização de arquivos.
  Future<ExerciseUpdateResult> updateExercise({
    required ExerciseDetailData original,
    required ExerciseUpdate update,
  });
}

/// Implementação em memória do repositório de exercícios utilizada em testes
/// de unidade e testes de widget para desacoplar as chamadas remotas do Firebase.
class LocalExerciseDetailRepository implements ExerciseDetailRepository {
  LocalExerciseDetailRepository({ExerciseDetailData? initialExercise})
    : _exercise = initialExercise;

  ExerciseDetailData? _exercise;

  @override
  Future<ExerciseDetailData> getExercise({String? id, String? code}) async {
    final current = _exercise;
    if (current == null) {
      throw const ExerciseDetailFailure('Exercício não encontrado.');
    }
    return current;
  }

  @override
  Future<ExerciseUpdateResult> updateExercise({
    required ExerciseDetailData original,
    required ExerciseUpdate update,
  }) async {
    // Validação de regra de negócio: exercício específico requer cavalo vinculado.
    if (update.privacy == ExerciseType.specific &&
        (update.horse == null || update.horse!.id.trim().isEmpty)) {
      throw const ExerciseDetailFailure(
        'Selecione o cavalo do exercício específico.',
      );
    }

    // Processamento local de remoção de mídias.
    final removedSet = update.removedMediaPaths.toSet();
    final remainingImages = original.images
        .where((item) => !removedSet.contains(item.path))
        .toList();
    final remainingVideos = original.videos
        .where((item) => !removedSet.contains(item.path))
        .toList();

    // Processamento local de adição de novas mídias simuladas.
    for (var i = 0; i < update.addedMedia.length; i++) {
      final media = update.addedMedia[i];
      final detailMedia = ExerciseDetailMedia(
        path: '/local/${media.name}',
        url: media.path.isNotEmpty ? media.path : 'https://local/${media.name}',
        type: media.type,
      );
      if (media.type == ExerciseMediaType.video) {
        remainingVideos.add(detailMedia);
      } else {
        remainingImages.add(detailMedia);
      }
    }

    // Montagem da entidade atualizada em memória.
    final updated = original.copyWith(
      name: update.name.trim(),
      description: update.description.trim(),
      defaultDurationMinutes: update.defaultDurationMinutes,
      guidelines: List.unmodifiable(
        update.guidelines
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty),
      ),
      materials: List.unmodifiable(update.materials),
      privacy: update.privacy,
      horse: update.privacy == ExerciseType.specific ? update.horse : null,
      clearHorse: update.privacy == ExerciseType.generic,
      images: List.unmodifiable(remainingImages),
      videos: List.unmodifiable(remainingVideos),
      updatedAt: DateTime.now().toUtc(),
    );
    _exercise = updated;
    return ExerciseUpdateResult(exercise: updated);
  }
}
