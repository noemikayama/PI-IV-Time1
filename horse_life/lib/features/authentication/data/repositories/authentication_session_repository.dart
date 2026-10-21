// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do contrato para observar e encerrar a sessão persistente.
// -----------------------------------------------------------------------------

import '../../application/states/login_session.dart';

abstract interface class AuthenticationSessionRepository {
  Stream<LoginSession?> watchSession();

  Future<void> signOut();
}
