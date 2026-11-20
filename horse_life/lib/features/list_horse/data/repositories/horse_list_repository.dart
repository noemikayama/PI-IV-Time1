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
// Alteração: Contrato remoto para a callable listHorses.
// -----------------------------------------------------------------------------

import '../models/horse_list_item.dart';

abstract class HorseListRepository {
  /// Executa a consulta real com filtro por nome e ordenação no backend.
  Future<List<HorseListItem>> listHorses({
    required HorseListProfile profile,
    String search = '',
    HorseSortOrder order = HorseSortOrder.alphabeticalAsc,
  });
}
