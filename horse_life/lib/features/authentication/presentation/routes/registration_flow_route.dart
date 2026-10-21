// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da rota que concentra a composição e a abertura do
// fluxo de cadastro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../application/controllers/registration_controller.dart';
import '../../data/repositories/firebase_guardian_registration_repository.dart';
import '../screens/profile_selection_screen.dart';

// Mantém a composição do cadastro fora das telas que apenas abrem o fluxo.
abstract final class RegistrationFlowRoute {
  static Route<void> build({
    ProfileSelectionCallback? onContinue,
    RegistrationController? registrationController,
  }) {
    final controller =
        registrationController ??
        const RegistrationController(FirebaseGuardianRegistrationRepository());

    return MaterialPageRoute<void>(
      builder: (context) => ProfileSelectionScreen(
        onContinue: onContinue,
        registrationController: controller,
      ),
    );
  }
}
