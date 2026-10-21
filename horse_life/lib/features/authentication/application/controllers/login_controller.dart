// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do controller que conecta a tela ao repositório de login.
// -----------------------------------------------------------------------------

import '../../data/repositories/login_repository.dart';
import '../states/login_session.dart';

class LoginController {
  const LoginController(this._repository);

  final LoginRepository _repository;

  Future<LoginSession> authenticate(String email, String password) {
    return _repository.authenticate(email: email, password: password);
  }
}
