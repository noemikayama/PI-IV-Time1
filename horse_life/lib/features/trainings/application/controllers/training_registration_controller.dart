// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição do callback opcional onTrainingCreated e do método
// withOnTrainingCreated para retorno integrado ao fluxo de planos de treino.
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Integração de sumExerciseDurations e registerTraining no controlador
// do fluxo de cadastro de treinamentos, mantendo fallback seguro da soma local.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do controlador de cadastro de treinamentos para consulta
// da galeria de exercícios (genéricos/específicos), cavalos vinculados e
// sincronização de exercícios criados durante a mesma sessão.
// -----------------------------------------------------------------------------

import '../../../exercises/application/states/exercise_registration_draft.dart';
import '../../../exercises/data/models/exercise_type.dart';
import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../../../exercises/data/repositories/trainer_linked_horse_repository.dart';
import '../../data/models/training_exercise_item.dart';
import '../../data/repositories/training_exercise_gallery_repository.dart';
import '../../data/repositories/training_registration_repository.dart';
import '../states/training_registration_draft.dart';

/// Encaminha as operações das etapas do cadastro de treinamentos às camadas de
/// repositório sem expor detalhes de infraestrutura às telas.
class TrainingRegistrationController {
  TrainingRegistrationController({
    TrainingExerciseGalleryRepository galleryRepository =
        const LocalTrainingExerciseGalleryRepository(),
    TrainerLinkedHorseRepository horseRepository =
        const LocalTrainerLinkedHorseRepository(),
    TrainingRegistrationRepository registrationRepository =
        const LocalTrainingRegistrationRepository(),
    this.onTrainingCreated,
  }) : _galleryRepository = galleryRepository,
       _horseRepository = horseRepository,
       _registrationRepository = registrationRepository;

  final TrainingExerciseGalleryRepository _galleryRepository;
  final TrainerLinkedHorseRepository _horseRepository;
  final TrainingRegistrationRepository _registrationRepository;
  final void Function(
    TrainingRegistrationDraft draft,
    TrainingRegistrationResult? result,
  )?
  onTrainingCreated;
  final List<TrainingExerciseItem> _sessionCreatedExercises = [];

  /// Cria uma cópia do controlador preservando os repositórios e vinculando um
  /// callback acionado após a conclusão do cadastro do treinamento.
  TrainingRegistrationController withOnTrainingCreated(
    void Function(
      TrainingRegistrationDraft draft,
      TrainingRegistrationResult? result,
    )?
    callback,
  ) {
    return TrainingRegistrationController(
      galleryRepository: _galleryRepository,
      horseRepository: _horseRepository,
      registrationRepository: _registrationRepository,
      onTrainingCreated: callback,
    );
  }

  /// Obtém e normaliza a lista de cavalos vinculados ao treinador autenticado.
  Future<List<TrainerLinkedHorse>> fetchLinkedHorses() async {
    final horses = await _horseRepository.fetchLinkedHorses();
    return horses
        .map(
          (horse) => TrainerLinkedHorse(
            id: horse.id.trim(),
            name: horse.name.trim(),
          ),
        )
        .where((horse) => horse.name.isNotEmpty)
        .toList(growable: false);
  }

  /// Registra um exercício recém-criado pelo treinador a partir do fluxo de
  /// treinamentos para refletir imediatamente em ambientes locais ou enquanto
  /// a próxima consulta remota é consolidada.
  TrainingExerciseItem recordCreatedExerciseFromDraft(
    ExerciseRegistrationDraft draft, {
    String? id,
  }) {
    final item = TrainingExerciseItem.fromExerciseDraft(draft, id: id);
    final alreadyStored = _sessionCreatedExercises.any(
      (existing) => _isSameExercise(existing, item),
    );
    if (!alreadyStored) {
      _sessionCreatedExercises.add(item);
    }
    return item;
  }

  /// Consulta os exercícios disponíveis na galeria de acordo com o filtro
  /// opcional de busca textual e cavalo vinculado. Sem `horseId`, retorna apenas
  /// exercícios genéricos; com `horseId`, apenas os específicos daquele cavalo.
  Future<List<TrainingExerciseItem>> fetchGalleryExercises({
    String? searchQuery,
    String? horseId,
  }) async {
    final remoteItems = await _galleryRepository.fetchGalleryExercises(
      searchQuery: searchQuery,
      horseId: horseId,
    );

    final trimmedHorseId = horseId?.trim() ?? '';
    final normalizedSearch = normalizeSearchText(searchQuery ?? '');

    final matchingSessionItems = _sessionCreatedExercises.where((exercise) {
      if (trimmedHorseId.isEmpty) {
        if (exercise.exerciseType != ExerciseType.generic) return false;
      } else {
        if (exercise.exerciseType != ExerciseType.specific ||
            exercise.horse?.id != trimmedHorseId) {
          return false;
        }
      }
      if (normalizedSearch.isNotEmpty &&
          !normalizeSearchText(exercise.name).contains(normalizedSearch)) {
        return false;
      }
      return true;
    });

    final combined = <TrainingExerciseItem>[...remoteItems];
    for (final sessionItem in matchingSessionItems) {
      final exists = combined.any(
        (existing) => _isSameExercise(existing, sessionItem),
      );
      if (!exists) {
        combined.add(sessionItem);
      }
    }

    combined.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return List.unmodifiable(combined);
  }

  /// Soma as durações padrão dos exercícios selecionados consultando o
  /// repositório configurado e preservando fallback local em caso de erro ou
  /// exercício ainda com identificador provisório de sessão.
  Future<int> sumExerciseDurations(List<TrainingExerciseItem> exercises) async {
    final localSum = exercises.fold<int>(
      0,
      (total, exercise) => total + exercise.estimatedDurationMinutes,
    );
    if (exercises.isEmpty ||
        exercises.any((exercise) => exercise.id.startsWith('local-'))) {
      return localSum;
    }

    try {
      return await _registrationRepository.sumExerciseDurations(
        exercises: exercises,
      );
    } on Object {
      return localSum;
    }
  }

  /// Submete o rascunho consolidado do treinamento ao repositório configurado.
  Future<TrainingRegistrationResult> registerTraining({
    required TrainingRegistrationDraft draft,
  }) {
    return _registrationRepository.registerTraining(draft: draft);
  }

  bool _isSameExercise(TrainingExerciseItem a, TrainingExerciseItem b) {
    if (a.id == b.id) return true;
    return a.name.trim().toLowerCase() == b.name.trim().toLowerCase() &&
        a.exerciseType == b.exerciseType &&
        a.horse?.id == b.horse?.id;
  }
}
