// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Definição do contrato de recuperação de senha e das falhas seguras
// que podem ser apresentadas pela interface.
// -----------------------------------------------------------------------------

// Falha tipada que impede a camada visual de depender de exceções do Firebase.
class PasswordResetFailure implements Exception {
  const PasswordResetFailure(this.message);

  const PasswordResetFailure.invalidEmail() : message = 'E-mail inválido.';

  const PasswordResetFailure.connection()
    : message = 'Erro de conexão com o servidor';

  final String message;
}

// Porta de saída usada pelo controller para solicitar o e-mail de recuperação.
abstract interface class PasswordResetRepository {
  Future<String> requestPasswordReset({required String email});
}
