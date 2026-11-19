// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do adapter Firebase para listagem da galeria de exercícios
// do treinador via Cloud Function listExerciseGallery na região southamerica-east1.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import '../../../exercises/data/models/exercise_type.dart';
import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../models/training_exercise_item.dart';
import 'training_exercise_gallery_repository.dart';

// Seam da callable para permitir testes de serialização, parse e tratamento de erros.
typedef TrainingExerciseGalleryCall =
    Future<Object?> Function(Map<String, Object?> payload);

/// Implementa a consulta da galeria de exercícios usando a callable
/// `listExerciseGallery` conforme especificado em docs/contrato_treinamentos.md.
final class FirebaseTrainingExerciseGalleryRepository
    implements TrainingExerciseGalleryRepository {
  const FirebaseTrainingExerciseGalleryRepository({
    TrainingExerciseGalleryCall? listExerciseGallery,
  }) : _listExerciseGallery = listExerciseGallery;

  static const _region = 'southamerica-east1';
  static const _functionName = 'listExerciseGallery';

  final TrainingExerciseGalleryCall? _listExerciseGallery;

  @override
  Future<List<TrainingExerciseItem>> fetchGalleryExercises({
    String? searchQuery,
    String? horseId,
  }) async {
    final trimmedSearch = searchQuery?.trim() ?? '';
    final trimmedHorseId = horseId?.trim() ?? '';

    final payload = <String, Object?>{
      if (trimmedSearch.isNotEmpty) 'busca': trimmedSearch,
      if (trimmedHorseId.isNotEmpty) 'cavaloId': trimmedHorseId,
    };

    try {
      final response = await (_listExerciseGallery ?? _callFromFirebase)(
        payload,
      );
      if (response is! Map) {
        throw const FormatException('Resposta da galeria de exercícios inválida.');
      }

      final rawList = response['exercicios'];
      if (rawList is! List) {
        throw const FormatException('Lista de exercícios da galeria inválida.');
      }

      return rawList.map(_parseExerciseItem).toList(growable: false);
    } on FirebaseFunctionsException catch (error) {
      throw TrainingGalleryFailure(
        error.message ?? 'Não foi possível carregar a galeria de exercícios.',
      );
    } on FormatException catch (error) {
      throw TrainingGalleryFailure(error.message);
    }
  }

  TrainingExerciseItem _parseExerciseItem(Object? item) {
    if (item is! Map) {
      throw const FormatException('Item de exercício na galeria inválido.');
    }

    final id = _extractId(item['id'] ?? item['_id']);
    final name = item['nome'];
    final rawDuration = item['duracaoPadraoMinutos'];
    final privacy = item['privacidade'];

    if (id.isEmpty || name is! String || name.trim().isEmpty) {
      throw const FormatException('Dados do exercício na galeria incompletos.');
    }

    final durationMinutes = switch (rawDuration) {
      final int value => value,
      final num value => value.toInt(),
      _ => 0,
    };

    final exerciseType = privacy == 'ESPECIFICO'
        ? ExerciseType.specific
        : ExerciseType.generic;

    TrainerLinkedHorse? horse;
    final rawHorse = item['cavalo'];
    if (rawHorse is Map) {
      final horseId = _extractId(rawHorse['id'] ?? rawHorse['_id']);
      final horseName = rawHorse['nome'];
      if (horseId.isNotEmpty && horseName is String && horseName.trim().isNotEmpty) {
        horse = TrainerLinkedHorse(id: horseId, name: horseName.trim());
      }
    }

    return TrainingExerciseItem(
      id: id,
      name: name.trim(),
      estimatedDurationMinutes: durationMinutes,
      exerciseType: exerciseType,
      horse: horse,
    );
  }

  String _extractId(Object? rawId) {
    return switch (rawId) {
      final String value when value.trim().isNotEmpty => value.trim(),
      final Map<Object?, Object?> oidMap when oidMap[r'$oid'] is String =>
        (oidMap[r'$oid'] as String).trim(),
      _ => '',
    };
  }

  Future<Object?> _callFromFirebase(Map<String, Object?> payload) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_functionName).call<dynamic>(payload);
    return result.data;
  }
}
