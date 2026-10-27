// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do contrato de login e da falha segura apresentada pela
// interface de autenticação.
// -----------------------------------------------------------------------------

import '../../application/states/login_session.dart';

class LoginFailure implements Exception {
  const LoginFailure(this.message);

  const LoginFailure.invalidCredentials()
    : message = 'E-mail ou senha incorretos';

  const LoginFailure.connection() : message = 'Erro de conexão com o servidor';

  final String message;
}

abstract interface class LoginRepository {
  Future<LoginSession> authenticate({
    required String email,
    required String password,
  });
}
