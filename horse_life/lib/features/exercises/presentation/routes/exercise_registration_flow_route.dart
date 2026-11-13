// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
import '../../data/repositories/firebase_exercise_registration_repository.dart';
import '../../data/repositories/trainer_linked_horse_repository.dart';
import '../screens/exercise_type_selection_screen.dart';

// Mantém a composição do cadastro de exercícios fora das telas que apenas
// iniciam o fluxo.
//
// Específico (8 etapas): tipo -> cavalo -> nome -> descrição -> orientações -> duração -> ...
// Genérico (7 etapas): tipo -> nome -> descrição -> orientações -> duração -> ...
abstract final class ExerciseRegistrationFlowRoute {
  static Route<void> build({
    ExerciseTypeSelectionCallback? onContinue,
    ExerciseRegistrationController? registrationController,
    TrainerLinkedHorseRepository? horseRepository,
  }) {
    // Utiliza o mock estático por padrão enquanto a Cloud Function de vínculos
    // não está pronta; para ativar a busca remota, basta substituir por
    // `const FirebaseTrainerLinkedHorseRepository()`.
    final resolvedHorseRepository =
        horseRepository ?? const LocalTrainerLinkedHorseRepository();
    final resolvedController =
        registrationController ??
        ExerciseRegistrationController(
          const FirebaseExerciseRegistrationRepository(),
          horseRepository: resolvedHorseRepository,
        );

    return MaterialPageRoute<void>(
      builder: (context) => ExerciseTypeSelectionScreen(
        onContinue: onContinue,
        registrationController: resolvedController,
        horseRepository: resolvedHorseRepository,
      ),
    );
  }
}
