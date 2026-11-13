// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO: 12/11/2026 - Contrato remoto para a callable listHorses.

import '../models/horse_list_item.dart';

abstract class HorseListRepository {
  /// Executa a consulta real com filtro por nome e ordenação no backend.
  Future<List<HorseListItem>> listHorses({
    required HorseListProfile profile,
    String search = '',
    HorseSortOrder order = HorseSortOrder.alphabeticalAsc,
  });
}
