// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Centralização das mensagens de erro apresentadas no login.
// -----------------------------------------------------------------------------

// Textos apresentados pela camada de interface durante falhas de login.
// A centralização evita divergências entre telas e testes da autenticação.
abstract final class AuthenticationErrorMessages {
  static const invalidCredentials = 'E-mail ou senha incorretos';
  static const serverConnection = 'Erro de conexão com o servidor';
}
