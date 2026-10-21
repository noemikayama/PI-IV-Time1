// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da rota que concentra a abertura e a composição do fluxo,
// escolhendo o controller do perfil e a fonte remota de modalidades.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../application/controllers/registration_controller.dart';
import '../../data/models/user_type.dart';
import '../../data/repositories/firebase_guardian_registration_repository.dart';
import '../../data/repositories/firebase_trainer_registration_repository.dart';
import '../../data/repositories/firebase_training_sport_repository.dart';
import '../../data/repositories/training_sport_repository.dart';
import '../screens/profile_selection_screen.dart';

// Mantém a composição do cadastro fora das telas que apenas abrem o fluxo.
abstract final class RegistrationFlowRoute {
  static Route<void> build({
    ProfileSelectionCallback? onContinue,
    RegistrationController? guardianController,
    RegistrationController? trainerController,
    TrainingSportRepository? trainerSportRepository,
  }) {
    final resolvedGuardianController =
        guardianController ??
        const RegistrationController(FirebaseGuardianRegistrationRepository());
    final resolvedTrainerController =
        trainerController ??
        const RegistrationController(FirebaseTrainerRegistrationRepository());

    return MaterialPageRoute<void>(
      builder: (context) => ProfileSelectionScreen(
        onContinue: onContinue,
        registrationControllerFor: (userType) => switch (userType) {
          UserType.guardian => resolvedGuardianController,
          UserType.trainer => resolvedTrainerController,
        },
        trainerSportRepository:
            trainerSportRepository ?? const FirebaseTrainingSportRepository(),
      ),
    );
  }
}
