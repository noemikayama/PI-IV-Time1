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
// Alteração: Criação do controller que conecta a tela ao repositório de login.
// -----------------------------------------------------------------------------

import '../../data/repositories/login_repository.dart';
import '../states/login_session.dart';

// Caso de uso de login: a apresentação fornece as credenciais e recebe uma
// sessão tipada, enquanto o adapter concreto permanece atrás do contrato.
class LoginController {
  const LoginController(this._repository);

  // Porta de saída que pode apontar para Firebase ou para outra infraestrutura.
  final LoginRepository _repository;

  // Não normaliza nem traduz falhas: essas regras pertencem ao repositório.
  Future<LoginSession> authenticate(String email, String password) {
    return _repository.authenticate(email: email, password: password);
  }
}
