// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da rota que compõe o controller e o adapter Firebase do
// fluxo de login fora das telas e encerra o fluxo sem callback de sessão.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../application/controllers/login_controller.dart';
import '../../data/repositories/firebase_login_repository.dart';
import '../screens/login_screen.dart';

abstract final class LoginFlowRoute {
  static Route<void> build({LoginController? controller}) {
    final resolvedController =
        controller ?? const LoginController(FirebaseLoginRepository());

    return MaterialPageRoute<void>(
      builder: (context) => LoginScreen(login: resolvedController.authenticate),
    );
  }
}
