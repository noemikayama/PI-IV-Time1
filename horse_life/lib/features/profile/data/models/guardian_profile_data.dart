// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos modelos e dos campos usados no fluxo de perfil.
//
// Data: 04/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do modelo de resultado da atualização do perfil, contendo
// o nome salvo e a data de atualização.
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação das responsabilidades dos modelos de perfil.
//
// Data: 28/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos modelos imutáveis do perfil do responsável e dos
// cavalos vinculados a ele.
// -----------------------------------------------------------------------------

/// Resumo de um cavalo exibido no perfil do responsável.
class GuardianProfileHorse {
  const GuardianProfileHorse({required this.name, required this.relationship});

  final String name;

  /// Papel do responsável em relação ao cavalo, pronto para exibição.
  final String relationship;
}

/// Dados necessários para montar a tela de perfil do responsável.
class GuardianProfileData {
  const GuardianProfileData({
    required this.name,
    required this.email,
    required this.horses,
  });

  final String name;
  final String email;

  /// Lista imutável de resumos exibidos na seção "Meus cavalos".
  final List<GuardianProfileHorse> horses;
}

/// Resultado devolvido pelo backend depois da alteração do nome.
class GuardianProfileUpdate {
  const GuardianProfileUpdate({required this.name, required this.updatedAt});

  /// Nome completo persistido e devolvido pelo backend.
  final String name;

  /// Instante confirmado pelo backend para a atualização.
  final DateTime updatedAt;
}
