// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do controlador que conecta a tela de recuperação ao
// contrato abstrato do repositório de redefinição de senha.
// -----------------------------------------------------------------------------

import '../../data/repositories/password_reset_repository.dart';

// Coordena a solicitação sem expor Firebase ou serialização à apresentação.
class PasswordResetController {
  const PasswordResetController(this._repository);

  // Dependência abstrata para permitir composição de produção e testes.
  final PasswordResetRepository _repository;

  // Encaminha somente o e-mail; validação remota e resposta ficam no adapter.
  Future<String> requestPasswordReset(String email) {
    return _repository.requestPasswordReset(email: email);
  }
}
