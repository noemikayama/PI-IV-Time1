// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação e comentários explicativos para
// facilitar a leitura e manutenção dos modelos de domínio de exercícios.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos modelos de domínio para visualização e edição de
// exercícios (ExerciseDetailMedia, ExerciseDetailData, ExerciseUpdate e
// ExerciseUpdateResult), alinhados aos contratos de getExercise e updateExercise.
// -----------------------------------------------------------------------------

import '../../application/states/exercise_material.dart';
import '../../application/states/exercise_media.dart';
import 'exercise_type.dart';
import 'trainer_linked_horse.dart';

/// Mídia auxiliar já persistida no backend e exibida na visualização/edição.
///
/// Encapsula o caminho relativo no Cloud Storage ([path]), a URL de download
/// assinada ([url]) e a classificação do arquivo ([type]) como imagem ou vídeo.
final class ExerciseDetailMedia {
  const ExerciseDetailMedia({
    required this.path,
    required this.url,
    required this.type,
  });

  /// Caminho relativo de armazenamento no Firebase Storage (ex: 'users/.../exercise.mp4').
  final String path;

  /// URL de acesso HTTPS (com token de download assinado).
  final String url;

  /// Tipo da mídia (imagem ou vídeo).
  final ExerciseMediaType type;

  /// Nome amigável do arquivo extraído de [path] ou [url] sem query string.
  ///
  /// Utilizado para exibição legível nos blocos de mídias anexadas e testes.
  String get fileName {
    final fromPath = _extractLastSegment(path);
    if (fromPath.isNotEmpty) return fromPath;
    final uri = Uri.tryParse(url);
    final fromUrl = uri != null ? _extractLastSegment(uri.path) : '';
    return fromUrl.isNotEmpty ? fromUrl : 'Mídia';
  }

  /// Infere se a mídia é imagem ou vídeo com base na extensão do arquivo em
  /// [path] ou [url], recorrendo a [fallback] quando não houver extensão reconhecida.
  ///
  /// Essa inferência garante que mídias salvas com formatos de vídeo padrão
  /// (.mp4, .mov, etc.) sejam encaminhadas diretamente ao reprodutor de vídeo
  /// mesmo se o metadata remoto reportar um tipo genérico.
  static ExerciseMediaType inferMediaType({
    required String path,
    required String url,
    required ExerciseMediaType fallback,
  }) {
    final extension = _extractExtension(path) ?? _extractExtension(url);
    if (extension == null) return fallback;
    const videoExtensions = {'mp4', 'mov', 'webm', 'mkv', 'avi', 'm4v'};
    const imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
    if (videoExtensions.contains(extension)) {
      return ExerciseMediaType.video;
    }
    if (imageExtensions.contains(extension)) {
      return ExerciseMediaType.image;
    }
    return fallback;
  }

  static String _extractLastSegment(String raw) {
    final normalized = raw.trim().split('?').first;
    final segments = normalized
        .split('/')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    return segments.isEmpty ? '' : segments.last;
  }

  static String? _extractExtension(String raw) {
    final cleaned = raw.trim().split('?').first.split('#').first;
    final lastDot = cleaned.lastIndexOf('.');
    if (lastDot < 0 || lastDot == cleaned.length - 1) return null;
    final ext = cleaned.substring(lastDot + 1).toLowerCase();
    return ext.contains('/') ? null : ext;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseDetailMedia &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          url == other.url &&
          type == other.type;

  @override
  int get hashCode => Object.hash(path, url, type);
}

/// Retrato completo de um exercício retornado pela Cloud Function `getExercise`.
///
/// Contém todos os dados cadastrais (título, descrição, duração padrão),
/// diretrizes de execução, lista de materiais, classificação de privacidade
/// (genérico vs específico), cavalo vinculado (se específico), lista de mídias
/// atreladas e indicação se o usuário autenticado possui privilégio de edição.
final class ExerciseDetailData {
  const ExerciseDetailData({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.defaultDurationMinutes,
    required this.guidelines,
    required this.materials,
    required this.privacy,
    required this.images,
    required this.videos,
    required this.canEdit,
    this.horse,
    this.trainerId,
    this.trainerName,
    this.createdAt,
    this.updatedAt,
  });

  /// Identificador único (ObjectId de 24 caracteres hexadecimais).
  final String id;

  /// Código numérico incremental do exercício para busca direta.
  final int code;

  /// Nome do exercício (3 a 80 caracteres).
  final String name;

  /// Descrição detalhada do exercício (até 1000 caracteres).
  final String description;

  /// Duração padrão sugerida em minutos (1 a 240).
  final int defaultDurationMinutes;

  /// Orientações e recomendações técnicas para a execução do exercício.
  final List<String> guidelines;

  /// Materiais necessários com suas respectivas quantidades.
  final List<ExerciseMaterial> materials;

  /// Tipo de privacidade ([ExerciseType.generic] ou [ExerciseType.specific]).
  final ExerciseType privacy;

  /// Cavalo vinculado (obrigatório caso [privacy] seja [ExerciseType.specific]).
  final TrainerLinkedHorse? horse;

  /// Identificador do treinador proprietário/criador do exercício.
  final String? trainerId;

  /// Nome do treinador criador (quando disponibilizado pelo backend).
  final String? trainerName;

  /// Imagens cadastradas no backend.
  final List<ExerciseDetailMedia> images;

  /// Vídeos cadastrados no backend.
  final List<ExerciseDetailMedia> videos;

  /// Sinalizador booleano retornado pelo backend informando se o usuário pode editar.
  final bool canEdit;

  /// Data de criação do registro.
  final DateTime? createdAt;

  /// Data da última alteração.
  final DateTime? updatedAt;

  /// Lista unificada das mídias auxiliares (imagens seguidas de vídeos).
  List<ExerciseDetailMedia> get allMedia =>
      List.unmodifiable([...images, ...videos]);

  /// Duração estimada formatada para apresentação na tela (ex: '20 min').
  String get formattedDuration => '$defaultDurationMinutes min';

  /// Rótulo em minúsculas da privacidade para exibição fiel ao protótipo ('genérico'/'específico').
  String get privacyDisplayLabel =>
      privacy == ExerciseType.specific ? 'específico' : 'genérico';

  /// Descrição normalizada ou texto informativo caso esteja vazia.
  String get displayDescription =>
      description.trim().isNotEmpty ? description.trim() : 'Não informada';

  /// Determina se o usuário autenticado pode editar este exercício.
  ///
  /// Prioriza [canEditOverride] caso seja fornecido (útil para testes unitários);
  /// em seguida, valida a igualdade entre [currentUserId] e o id do autor [trainerId],
  /// respeitando também a flag booleana de autorização retornada pelo backend [canEdit].
  bool resolveCanEdit({String? currentUserId, bool? canEditOverride}) {
    if (canEditOverride != null) return canEditOverride;
    final normalizedTrainerId = trainerId?.trim() ?? '';
    final normalizedCurrentUserId = currentUserId?.trim() ?? '';
    if (normalizedTrainerId.isNotEmpty && normalizedCurrentUserId.isNotEmpty) {
      return canEdit && normalizedCurrentUserId == normalizedTrainerId;
    }
    return canEdit;
  }

  /// Gera uma cópia imutável com campos atualizados.
  ExerciseDetailData copyWith({
    String? id,
    int? code,
    String? name,
    String? description,
    int? defaultDurationMinutes,
    List<String>? guidelines,
    List<ExerciseMaterial>? materials,
    ExerciseType? privacy,
    TrainerLinkedHorse? horse,
    bool clearHorse = false,
    String? trainerId,
    String? trainerName,
    List<ExerciseDetailMedia>? images,
    List<ExerciseDetailMedia>? videos,
    bool? canEdit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExerciseDetailData(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      defaultDurationMinutes:
          defaultDurationMinutes ?? this.defaultDurationMinutes,
      guidelines: guidelines != null
          ? List.unmodifiable(guidelines)
          : this.guidelines,
      materials: materials != null
          ? List.unmodifiable(materials)
          : this.materials,
      privacy: privacy ?? this.privacy,
      horse: clearHorse ? null : (horse ?? this.horse),
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      images: images != null ? List.unmodifiable(images) : this.images,
      videos: videos != null ? List.unmodifiable(videos) : this.videos,
      canEdit: canEdit ?? this.canEdit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Conjunto de alterações consolidadas no formulário de edição de exercícios.
///
/// Encapsula modificações de campos textuais/numéricos, mudanças de privacidade,
/// vinculação de animal, lista de mídias marcadas para remoção e novos arquivos
/// selecionados para upload.
final class ExerciseUpdate {
  const ExerciseUpdate({
    required this.name,
    required this.description,
    required this.defaultDurationMinutes,
    required this.guidelines,
    required this.materials,
    required this.privacy,
    this.horse,
    this.removedMediaPaths = const [],
    this.addedMedia = const [],
  });

  /// Nome atualizado do exercício.
  final String name;

  /// Descrição atualizada do exercício.
  final String description;

  /// Duração padrão atualizada em minutos.
  final int defaultDurationMinutes;

  /// Lista atualizada de orientações.
  final List<String> guidelines;

  /// Lista atualizada de materiais e quantidades.
  final List<ExerciseMaterial> materials;

  /// Classificação de privacidade selecionada.
  final ExerciseType privacy;

  /// Cavalo selecionado (relevante apenas se [privacy] for [ExerciseType.specific]).
  final TrainerLinkedHorse? horse;

  /// Caminhos das mídias existentes que o usuário optou por excluir.
  final List<String> removedMediaPaths;

  /// Novos arquivos locais adicionados durante a sessão de edição.
  final List<ExerciseMedia> addedMedia;

  List<String> get _normalizedGuidelines => guidelines
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  /// Monta o payload JSON estrito esperado pela Cloud Function `updateExercise`.
  ///
  /// Conforme especificado na documentação do backend, a função `updateExercise`
  /// exige o `id` e **apenas os campos que efetivamente foram alterados**.
  /// Além disso, quando a privacidade for genérica o campo `cavaloId` não deve
  /// ser enviado, e quando for específica o `cavaloId` é obrigatório.
  Map<String, Object?> toUpdatePayload(ExerciseDetailData original) {
    final payload = <String, Object?>{'id': original.id.trim()};

    final trimmedName = name.trim();
    if (trimmedName != original.name.trim()) {
      payload['nome'] = trimmedName;
    }

    final trimmedDescription = description.trim();
    if (trimmedDescription != original.description.trim()) {
      payload['descricao'] = trimmedDescription;
    }

    if (defaultDurationMinutes != original.defaultDurationMinutes) {
      payload['duracaoPadraoMinutos'] = defaultDurationMinutes;
    }

    final nextGuidelines = _normalizedGuidelines;
    if (!_listEquals(nextGuidelines, original.guidelines)) {
      payload['orientacoes'] = nextGuidelines;
    }

    if (!_listEquals(materials, original.materials)) {
      payload['materiais'] = materials
          .map((item) => item.toJson())
          .toList(growable: false);
    }

    final privacyChanged = privacy != original.privacy;
    final horseChanged =
        privacy == ExerciseType.specific && horse?.id != original.horse?.id;

    if (privacyChanged || horseChanged) {
      if (privacy == ExerciseType.specific) {
        payload['privacidade'] = 'ESPECIFICO';
        if (horse != null) {
          payload['cavaloId'] = horse!.id.trim();
        }
      } else {
        payload['privacidade'] = 'GENERICO';
      }
    }

    return payload;
  }

  /// Indica se algum campo cadastral (nome, descrição, duração, listas ou privacidade)
  /// foi modificado em relação ao exercício original.
  bool hasFieldChanges(ExerciseDetailData original) =>
      toUpdatePayload(original).length > 1;

  /// Indica se houve remoção de mídias existentes ou adição de novos arquivos locais.
  bool get hasMediaChanges =>
      removedMediaPaths.isNotEmpty || addedMedia.isNotEmpty;

  /// Indica se houve qualquer alteração (cadastral ou de arquivos) pendente de salvamento.
  bool hasAnyChanges(ExerciseDetailData original) =>
      hasFieldChanges(original) || hasMediaChanges;

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Resultado retornado após o salvamento das alterações de um exercício.
///
/// Encapsula a entidade atualizada [exercise] e uma mensagem de advertência
/// opcional [warning] informando se alguma operação secundária de envio ou
/// remoção de mídia falhou parcialmente na nuvem.
final class ExerciseUpdateResult {
  const ExerciseUpdateResult({
    required this.exercise,
    this.warning,
  });

  /// Instância de exercício contendo os dados mais recentes persistidos.
  final ExerciseDetailData exercise;

  /// Advertência informativa sobre eventuais falhas parciais de mídias.
  final String? warning;

  /// Indica se há advertência a ser reportada ao usuário via SnackBar.
  bool get hasWarning => warning != null && warning!.trim().isNotEmpty;
}
