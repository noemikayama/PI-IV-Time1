// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Composição das Homes usa apenas repositórios reais.
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Centralização da composição temporária da Home (produção/fakes)
// durante o merge das features, evitando inicialização de Firebase nas telas.
// -----------------------------------------------------------------------------

import 'application/controllers/guardian_home_controller.dart';
import 'application/controllers/home_loader.dart';
import 'application/controllers/trainer_home_controller.dart';
import 'data/models/guardian_home_data.dart';
import 'data/models/trainer_home_data.dart';
import 'data/repositories/guardian_repository.dart';
import 'data/repositories/trainer_repository.dart';

/// Ponto de composição de transição. No projeto completo, AppDependencies
/// pode criar/injetar estes loaders na raiz; as telas aceitam HomeLoader<T>.
abstract final class HomeComposition {
  static HomeLoader<GuardianHomeData> guardian() {
    return GuardianHomeController(FirebaseGuardianRepository());
  }

  static HomeLoader<TrainerHomeData> trainer({
    TrainerRepository? repository,
  }) {
    return TrainerHomeController(
      repository ?? FirebaseTrainerRepository(),
    );
  }
}
