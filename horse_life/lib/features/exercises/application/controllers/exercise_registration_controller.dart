// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição do callback onExerciseCreatedWithId para propagar o
// identificador real do exercício criado no backend ao fluxo de treinamentos.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Inclusão do callback opcional onExerciseCreated para notificar
// fluxos chamadores (como cadastro de treinamentos) após a conclusão do exercício.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adoção do FirebaseTrainerLinkedHorseRepository como fonte padrão
// e retorno de ExerciseRegistrationResult em registerExercise.
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do controlador de aplicação responsável por intermediar
// a consulta de cavalos vinculados e a submissão do cadastro de exercícios.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import '../../data/models/trainer_linked_horse.dart';
import '../../data/repositories/exercise_registration_repository.dart';
import '../../data/repositories/firebase_trainer_linked_horse_repository.dart';
import '../../data/repositories/trainer_linked_horse_repository.dart';
import '../states/exercise_registration_draft.dart';

// Encaminha as operações do fluxo de cadastro de exercícios aos repositórios
// sem expor detalhes de infraestrutura ou Firebase às telas.
class ExerciseRegistrationController {
  const ExerciseRegistrationController(
    this._registrationRepository, {
    TrainerLinkedHorseRepository horseRepository =
        const FirebaseTrainerLinkedHorseRepository(),
    this.onExerciseCreated,
    this.onExerciseCreatedWithId,
  }) : _horseRepository = horseRepository;

  final ExerciseRegistrationRepository _registrationRepository;
  final TrainerLinkedHorseRepository _horseRepository;

  /// Callback opcional acionado com o rascunho consolidado após o envio do exercício.
  final ValueChanged<ExerciseRegistrationDraft>? onExerciseCreated;

  /// Callback opcional acionado com o rascunho consolidado e o identificador
  /// retornado pelo backend após o envio do exercício.
  final void Function(ExerciseRegistrationDraft draft, String? exerciseId)?
  onExerciseCreatedWithId;

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

  /// Submete o rascunho consolidado do exercício ao repositório configurado.
  Future<ExerciseRegistrationResult> registerExercise({
    required ExerciseRegistrationDraft draft,
  }) {
    return _registrationRepository.registerExercise(draft: draft);
  }

  /// Cria uma cópia do controlador preservando repositórios e vinculando um
  /// novo callback de conclusão do cadastro.
  ExerciseRegistrationController withOnExerciseCreated(
    ValueChanged<ExerciseRegistrationDraft>? callback, {
    void Function(ExerciseRegistrationDraft draft, String? exerciseId)?
    onExerciseCreatedWithId,
  }) {
    return ExerciseRegistrationController(
      _registrationRepository,
      horseRepository: _horseRepository,
      onExerciseCreated: callback,
      onExerciseCreatedWithId:
          onExerciseCreatedWithId ?? this.onExerciseCreatedWithId,
    );
  }
}
