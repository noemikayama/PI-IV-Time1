// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO DE ALTERAÇÕES
// 07/11/2026: Modelo de card da listagem de cavalos.
// 12/11/2026: Modelo exclusivo do retorno real da callable listHorses.

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
