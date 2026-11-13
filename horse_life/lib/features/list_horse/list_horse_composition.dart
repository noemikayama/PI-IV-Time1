// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 12/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Separa a fonte Firebase dos cenários demonstrativos da listagem.
// -----------------------------------------------------------------------------

import 'data/repositories/firebase_horse_list_repository.dart';
import 'domain/repositories/horse_list_repository.dart';

abstract final class ListHorseComposition {
  static HorseListRepository productionRepository() =>
      FirebaseHorseListRepository();
}
