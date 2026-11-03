// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
  final List<GuardianProfileHorse> horses;
}
