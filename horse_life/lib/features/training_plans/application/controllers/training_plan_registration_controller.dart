// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Usa dependências reais por padrão e conserva injeção para testes.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Integração de fetchTrainingGallery, sincronização de treinos criados
// na mesma sessão e createTrainingPlan no controlador do fluxo de planos.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do controlador de cadastro de planos de treinamento para
// consulta de animais vinculados ao treinador sem expor detalhes de
// infraestrutura às telas.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/training_plans/data/repositories/firebase_training_plan_repository.dart';
import 'package:horse_life/features/exercises/data/repositories/firebase_trainer_linked_horse_repository.dart';
import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../../../exercises/data/repositories/trainer_linked_horse_repository.dart';
import '../../../trainings/application/states/training_registration_draft.dart';
import '../../../trainings/data/repositories/training_exercise_gallery_repository.dart';
import '../../data/models/training_plan_gallery_item.dart';
import '../../data/repositories/training_plan_repository.dart';
import '../states/training_plan_registration_draft.dart';

/// Encaminha as operações das etapas do cadastro de planos de treinamento às
/// camadas de repositório sem expor detalhes de infraestrutura às telas.
class TrainingPlanRegistrationController {
  TrainingPlanRegistrationController({
    TrainerLinkedHorseRepository horseRepository =
        const FirebaseTrainerLinkedHorseRepository(),
    TrainingPlanRepository planRepository = const FirebaseTrainingPlanRepository(),
  }) : _horseRepository = horseRepository,
       _planRepository = planRepository;

  final TrainerLinkedHorseRepository _horseRepository;
  final TrainingPlanRepository _planRepository;
  final List<TrainingPlanGalleryItem> _sessionCreatedTrainings = [];

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

  /// Registra um treinamento recém-criado durante o fluxo do plano para refletir
  /// imediatamente na seleção da semana e na galeria.
  TrainingPlanGalleryItem recordCreatedTrainingFromDraft(
    TrainingRegistrationDraft draft, {
    required String id,
    required int code,
  }) {
    final item = TrainingPlanGalleryItem.fromTrainingDraft(
      draft,
      id: id,
      code: code,
    );
    final alreadyStored = _sessionCreatedTrainings.any(
      (existing) => _isSameTraining(existing, item),
    );
    if (!alreadyStored) {
      _sessionCreatedTrainings.add(item);
    }
    return item;
  }

  /// Consulta os treinamentos compatíveis com o cavalo informado, combinando
  /// com treinamentos recém-criados na sessão.
  Future<List<TrainingPlanGalleryItem>> fetchTrainingGallery({
    required String horseId,
    String? searchQuery,
  }) async {
    final remoteItems = await _planRepository.fetchTrainingGallery(
      horseId: horseId,
      searchQuery: searchQuery,
    );

    final normalizedSearch = normalizeSearchText(searchQuery ?? '');
    final matchingSessionItems = _sessionCreatedTrainings.where((item) {
      if (normalizedSearch.isNotEmpty &&
          !normalizeSearchText(item.title).contains(normalizedSearch)) {
        return false;
      }
      return true;
    });

    final combined = <TrainingPlanGalleryItem>[...remoteItems];
    for (final sessionItem in matchingSessionItems) {
      final exists = combined.any(
        (existing) => _isSameTraining(existing, sessionItem),
      );
      if (!exists) {
        combined.add(sessionItem);
      }
    }

    combined.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return List.unmodifiable(combined);
  }

  /// Submete o rascunho consolidado do plano de treinamento ao repositório.
  Future<TrainingPlanRegistrationResult> createTrainingPlan({
    required TrainingPlanRegistrationDraft draft,
  }) {
    return _planRepository.createTrainingPlan(draft: draft);
  }

  bool _isSameTraining(TrainingPlanGalleryItem a, TrainingPlanGalleryItem b) {
    if (a.id == b.id) return true;
    return a.title.trim().toLowerCase() == b.title.trim().toLowerCase();
  }
}
