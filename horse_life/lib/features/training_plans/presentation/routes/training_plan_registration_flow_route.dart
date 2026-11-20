// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Injeção do FirebaseTrainingPlanRepository no controlador da rota
// para consulta da galeria de treinamentos e submissão do plano.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da rota de entrada do fluxo de cadastro de planos de
// treinamento, compondo o controlador com FirebaseTrainerLinkedHorseRepository.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../exercises/data/repositories/firebase_trainer_linked_horse_repository.dart';
import '../../../exercises/data/repositories/trainer_linked_horse_repository.dart';
import '../../application/controllers/training_plan_registration_controller.dart';
import '../../data/repositories/firebase_training_plan_repository.dart';
import '../../data/repositories/training_plan_repository.dart';
import '../screens/training_plan_title_screen.dart';

/// Concentra a composição e abertura do cadastro de planos de treinamento fora
/// da Home, da agenda e da barra lateral do treinador.
abstract final class TrainingPlanRegistrationFlowRoute {
  static const routeName = '/training-plans/register';

  static Route<void> build({
    TrainingPlanRegistrationController? controller,
    TrainerLinkedHorseRepository? horseRepository,
    TrainingPlanRepository? planRepository,
  }) {
    final resolvedHorseRepository =
        horseRepository ?? const FirebaseTrainerLinkedHorseRepository();
    final resolvedPlanRepository =
        planRepository ?? const FirebaseTrainingPlanRepository();
    final resolvedController =
        controller ??
        TrainingPlanRegistrationController(
          horseRepository: resolvedHorseRepository,
          planRepository: resolvedPlanRepository,
        );

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: routeName),
      builder: (context) =>
          TrainingPlanTitleScreen(controller: resolvedController),
    );
  }
}
