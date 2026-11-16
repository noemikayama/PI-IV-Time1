// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Injeção do HorseRegistrationController na rota de cadastro,
// isolando as dependências de infraestrutura da interface de navegação.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Rota de abertura do cadastro, como RegistrationFlowRoute.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../application/controllers/horse_registration_controller.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../../horse_registration_composition.dart';
import '../screens/horse_relationship_screen.dart';
import '../services/horse_image_selection_service.dart';

/// Abre o fluxo sem exigir que a Home conheça as etapas internas.
abstract final class HorseRegistrationFlowRoute {
  static Route<HorseRegistrationResult> build({
    HorseRegistrationRepository? repository,
    HorseMicrochipValidator? microchipValidator,
    HorseRegistrationController? controller,
    HorseRegistrationDraft? draft,
    HorseImageSelectionService? imageSelection,
  }) {
    final resolvedController =
        controller ??
        HorseRegistrationComposition.productionController(
          repository: repository,
          microchipValidator: microchipValidator,
          initialDraft: draft,
        );

    return MaterialPageRoute<HorseRegistrationResult>(
      builder: (_) => HorseRelationshipScreen(
        controller: resolvedController,
        draft: resolvedController.draft,
        imageSelection: imageSelection ?? const HorseImageSelectionService(),
      ),
    );
  }
}
