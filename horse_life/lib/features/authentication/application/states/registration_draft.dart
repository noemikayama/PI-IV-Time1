// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do estado imutável do cadastro de responsável.
// -----------------------------------------------------------------------------

// Mantém os dados coletados entre as etapas do cadastro de responsável.
class RegistrationDraft {
  const RegistrationDraft({
    required this.firstName,
    required this.lastName,
    this.email = '',
  });

  // Dados não sensíveis acumulados durante as etapas do cadastro.
  // A senha não faz parte deste estado e nunca é persistida nele.
  final String firstName;
  final String lastName;
  final String email;

  // Produz a próxima versão imutável após a edição de uma etapa.
  RegistrationDraft copyWith({
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return RegistrationDraft(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
    );
  }
}
