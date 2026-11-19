// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Reorganização da camada de dados e atualização dos imports; padronização
// de autoria e histórico para revisão do PR.
//
// Data: 12/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Modelo exclusivo do retorno real da callable listHorses.
//
// Data: 07/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Modelo de card da listagem de cavalos.
// -----------------------------------------------------------------------------

/// Perfil esperado no retorno de listHorses, determinado pela autenticação.
enum HorseListProfile { guardian, professional }

/// Ordenações admitidas pela validação de listHorses no Firebase.
enum HorseSortOrder { alphabeticalAsc, alphabeticalDesc, recentDesc, recentAsc }

extension HorseSortOrderContract on HorseSortOrder {
  String get firebaseValue => switch (this) {
    HorseSortOrder.alphabeticalAsc => 'A_Z',
    HorseSortOrder.alphabeticalDesc => 'Z_A',
    HorseSortOrder.recentDesc => 'MAIS_RECENTES',
    HorseSortOrder.recentAsc => 'MAIS_ANTIGOS',
  };
}

/// Card derivado exclusivamente da resposta autenticada do Firebase.
class HorseListItem {
  final String id;
  final String name;
  final String relation;
  final String trainerName;
  final String ownerName;
  final String modality;
  final String? imageUrl;
  final DateTime linkedAt;

  const HorseListItem({
    required this.id,
    required this.name,
    required this.relation,
    required this.trainerName,
    required this.ownerName,
    required this.modality,
    required this.linkedAt,
    this.imageUrl,
  });
}
