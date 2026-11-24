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
// Alteração: Criação da sessão autenticada restrita aos papéis de responsável
// e treinador reconhecidos pelo aplicativo.
// -----------------------------------------------------------------------------

// Papéis reconhecidos pelo frontend depois da validação do token Firebase.
enum AuthenticationRole {
  guardian('guardian'),
  trainer('trainer');

  const AuthenticationRole(this.value);

  final String value;

  // Converte claims externos sem aceitar papéis desconhecidos pela aplicação.
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

  // Identidade e autorização mínimas necessárias para selecionar a Home.
  final String uid;
  final String name;
  final AuthenticationRole role;
}
