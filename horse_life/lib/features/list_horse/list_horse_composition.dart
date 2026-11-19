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
// Alteração: Separa a fonte Firebase dos cenários demonstrativos da listagem.
// -----------------------------------------------------------------------------

import 'data/repositories/firebase_horse_list_repository.dart';
import 'data/repositories/horse_list_repository.dart';

abstract final class ListHorseComposition {
  static HorseListRepository productionRepository() =>
      FirebaseHorseListRepository();
}
