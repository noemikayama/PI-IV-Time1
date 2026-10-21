// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da sessão autenticada restrita aos papéis de responsável
// e treinador reconhecidos pelo aplicativo.
// -----------------------------------------------------------------------------

enum AuthenticationRole {
  guardian('guardian'),
  trainer('trainer');

  const AuthenticationRole(this.value);

  final String value;

  static AuthenticationRole? fromValue(Object? value) {
    for (final role in values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

// Resultado imutável disponibilizado depois que o Firebase aceita o token.
class LoginSession {
  const LoginSession({
    required this.uid,
    required this.name,
    required this.role,
  });

  final String uid;
  final String name;
  final AuthenticationRole role;
}
