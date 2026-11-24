// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos e segmentos do código de autenticação,
// detalhando responsabilidades, fluxo de dados e integração entre camadas.
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
//
// Responsável: perfil -> nome -> e-mail -> senha -> confirmação.
// Treinador: perfil -> nome -> e-mail -> modalidade -> experiência ->
// certificações -> áreas -> senha -> confirmação.
abstract final class RegistrationFlowRoute {
  // Resolve uma implementação específica para cada perfil, pois somente o
  // cadastro profissional possui anexos, modalidade e áreas de atendimento.
  static Route<void> build({
    ProfileSelectionCallback? onContinue,
    RegistrationController? guardianController,
    RegistrationController? trainerController,
    TrainingSportRepository? trainerSportRepository,
  }) {
    // A composição padrão sempre usa adapters Firebase; parâmetros opcionais
    // preservam o mesmo fluxo com dependências controladas em testes.
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
