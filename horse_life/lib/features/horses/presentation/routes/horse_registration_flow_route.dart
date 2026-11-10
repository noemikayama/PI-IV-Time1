// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Rota de abertura do cadastro, como RegistrationFlowRoute.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../screens/horse_registration_screen.dart';

/// Abre o fluxo sem exigir que a Home conheça as etapas internas.
abstract final class HorseRegistrationFlowRoute {
  static Route<HorseRegistrationResult> build({
    HorseRegistrationRepository? repository,
    HorseMicrochipValidator? microchipValidator,
  }) => MaterialPageRoute<HorseRegistrationResult>(
    builder: (_) => HorseRegistrationScreen(
      repository: repository,
      microchipValidator: microchipValidator,
    ),
  );
}
