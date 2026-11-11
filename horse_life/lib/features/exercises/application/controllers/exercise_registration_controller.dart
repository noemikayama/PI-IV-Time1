// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do controlador de aplicação responsável por intermediar
// a consulta de cavalos vinculados e a submissão do cadastro de exercícios.
// -----------------------------------------------------------------------------

import '../../data/models/trainer_linked_horse.dart';
import '../../data/repositories/exercise_registration_repository.dart';
import '../../data/repositories/trainer_linked_horse_repository.dart';
import '../states/exercise_registration_draft.dart';

// Encaminha as operações do fluxo de cadastro de exercícios aos repositórios
// sem expor detalhes de infraestrutura ou Firebase às telas.
class ExerciseRegistrationController {
  const ExerciseRegistrationController(
    this._registrationRepository, {
    TrainerLinkedHorseRepository horseRepository =
        const LocalTrainerLinkedHorseRepository(),
  }) : _horseRepository = horseRepository;

  final ExerciseRegistrationRepository _registrationRepository;
  final TrainerLinkedHorseRepository _horseRepository;

  // Obtém e normaliza a lista de cavalos vinculados ao treinador autenticado.
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

  // Submete o rascunho consolidado do exercício ao repositório configurado.
  Future<void> registerExercise({
    required ExerciseRegistrationDraft draft,
  }) {
    return _registrationRepository.registerExercise(draft: draft);
  }
}
