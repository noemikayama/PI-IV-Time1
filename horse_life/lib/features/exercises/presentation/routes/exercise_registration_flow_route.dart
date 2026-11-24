// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Suporte ao callback opcional onExerciseCreatedWithId para
// encaminhamento do identificador real do exercício criado no backend.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Definição do routeName de entrada e suporte ao callback
// onExerciseCreated para retorno integrado ao fluxo de treinamentos.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Ativação definitiva do FirebaseTrainerLinkedHorseRepository e
// FirebaseExerciseRegistrationRepository como provedores reais da rota.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adoção do repositório estático LocalTrainerLinkedHorseRepository
// como fonte padrão temporária na rota de exercícios para permitir testes do
// fluxo específico sem depender de vínculos reais no banco de dados.
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da rota que concentra a abertura e a composição do fluxo
// de cadastro de exercícios, injetando o controlador e a fonte remota de
// cavalos vinculados ao treinador.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../application/controllers/exercise_registration_controller.dart';
import '../../application/states/exercise_registration_draft.dart';
import '../../data/repositories/firebase_exercise_registration_repository.dart';
import '../../data/repositories/firebase_trainer_linked_horse_repository.dart';
import '../../data/repositories/trainer_linked_horse_repository.dart';
import '../screens/exercise_type_selection_screen.dart';

// Mantém a composição do cadastro de exercícios fora das telas que apenas
// iniciam o fluxo.
//
// Específico (8 etapas): tipo -> cavalo -> nome -> descrição -> orientações -> duração -> ...
// Genérico (7 etapas): tipo -> nome -> descrição -> orientações -> duração -> ...
abstract final class ExerciseRegistrationFlowRoute {
  static const routeName = '/exercises/register';

  static Route<void> build({
    ExerciseTypeSelectionCallback? onContinue,
    ExerciseRegistrationController? registrationController,
    TrainerLinkedHorseRepository? horseRepository,
    ValueChanged<ExerciseRegistrationDraft>? onExerciseCreated,
    void Function(ExerciseRegistrationDraft draft, String? exerciseId)?
    onExerciseCreatedWithId,
  }) {
    final resolvedHorseRepository =
        horseRepository ?? const FirebaseTrainerLinkedHorseRepository();
    final resolvedController =
        registrationController ??
        ExerciseRegistrationController(
          FirebaseExerciseRegistrationRepository(),
          horseRepository: resolvedHorseRepository,
          onExerciseCreated: onExerciseCreated,
          onExerciseCreatedWithId: onExerciseCreatedWithId,
        );

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: routeName),
      builder: (context) => ExerciseTypeSelectionScreen(
        onContinue: onContinue,
        registrationController: resolvedController,
        horseRepository: resolvedHorseRepository,
      ),
    );
  }
}
