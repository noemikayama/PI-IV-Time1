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
// Alteração: Criação da rota que compõe o controller e o adapter Firebase do
// fluxo de login fora das telas e encerra o fluxo sem callback de sessão.
//
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Suporte à mensagem inicial de erro no login após o cadastro,
// preservando a injeção obrigatória do LoginController.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../application/controllers/login_controller.dart';
import '../../data/repositories/firebase_login_repository.dart';
import '../screens/login_screen.dart';

// Ponto de composição do login: instancia as dependências reais e entrega à
// tela somente a operação que ela precisa executar.
abstract final class LoginFlowRoute {
  // Controllers alternativos permitem reutilizar a mesma tela em testes sem
  // espalhar conhecimento sobre Firebase pela camada de apresentação.
  static Route<void> build({
    LoginController? controller,
    String? initialErrorMessage,
  }) {
    final resolvedController =
        controller ?? const LoginController(FirebaseLoginRepository());

    return MaterialPageRoute<void>(
      builder: (context) => LoginScreen(
        login: resolvedController.authenticate,
        initialErrorMessage: initialErrorMessage,
      ),
    );
  }
}
