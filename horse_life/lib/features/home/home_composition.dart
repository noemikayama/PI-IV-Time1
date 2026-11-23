// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Correção da referência genérica na documentação para evitar sua
// interpretação como HTML pelo analisador Dart.
//
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
import 'testing/fakes/mock_guardian_home_service.dart';
import 'testing/fakes/mock_trainer_home_service.dart';

/// Ponto de composição de transição. No projeto completo, AppDependencies
/// pode criar/injetar estes loaders na raiz; as telas aceitam `HomeLoader<T>`.
abstract final class HomeComposition {
  static HomeLoader<GuardianHomeData> guardian({String? mockScenario}) {
    if (mockScenario != null) {
      return _MockGuardianLoader(mockScenario);
    }
    return GuardianHomeController(FirebaseGuardianRepository());
  }

  static HomeLoader<TrainerHomeData> trainer({
    String? mockScenario,
    TrainerRepository? repository,
  }) {
    if (mockScenario != null) {
      return _MockTrainerLoader(mockScenario);
    }
    return TrainerHomeController(repository ?? FirebaseTrainerRepository());
  }
}

class _MockGuardianLoader implements HomeLoader<GuardianHomeData> {
  const _MockGuardianLoader(this.scenario);
  final String scenario;

  @override
  Future<GuardianHomeData> fetchHome() => const MockGuardianHomeService()
      .fetchHome(scenario: scenario, simulateError: scenario == 'error');
}

class _MockTrainerLoader implements HomeLoader<TrainerHomeData> {
  const _MockTrainerLoader(this.scenario);
  final String scenario;

  @override
  Future<TrainerHomeData> fetchHome() =>
      const MockTrainerHomeService().fetchHome(scenario: scenario);
}
