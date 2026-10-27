// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Centralização da composição temporária da Home (produção/fakes)
// durante o merge das features, evitando inicialização de Firebase nas telas.
// -----------------------------------------------------------------------------

import 'application/controllers/guardian_home_controller.dart';
import 'application/controllers/home_loader.dart';
import 'application/controllers/professional_home_controller.dart';
import 'data/models/guardian_home_data.dart';
import 'data/models/professional_home_data.dart';
import 'data/repositories/guardian_repository.dart';
import 'data/repositories/professional_repository.dart';
import 'testing/fakes/mock_guardian_home_service.dart';
import 'testing/fakes/mock_professional_home_service.dart';

/// Ponto de composição de transição. No projeto completo, AppDependencies
/// pode criar/injetar estes loaders na raiz; as telas aceitam HomeLoader<T>.
abstract final class HomeComposition {
  static HomeLoader<GuardianHomeData> guardian({String? mockScenario}) {
    if (mockScenario != null) {
      return _MockGuardianLoader(mockScenario);
    }
    return GuardianHomeController(FirebaseGuardianRepository());
  }

  static HomeLoader<ProfessionalHomeData> professional({
    String? mockScenario,
    ProfessionalRepository? repository,
  }) {
    if (mockScenario != null) {
      return _MockProfessionalLoader(mockScenario);
    }
    return ProfessionalHomeController(
      repository ?? FirebaseProfessionalRepository(),
    );
  }
}

class _MockGuardianLoader implements HomeLoader<GuardianHomeData> {
  const _MockGuardianLoader(this.scenario);
  final String scenario;

  @override
  Future<GuardianHomeData> fetchHome() =>
      const MockGuardianHomeService().fetchHome(
        scenario: scenario,
        simulateError: scenario == 'error',
      );
}

class _MockProfessionalLoader implements HomeLoader<ProfessionalHomeData> {
  const _MockProfessionalLoader(this.scenario);
  final String scenario;

  @override
  Future<ProfessionalHomeData> fetchHome() =>
      const MockProfessionalHomeService().fetchHome(scenario: scenario);
}
