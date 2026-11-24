// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Tela unificada e modularizada de notas e apontamentos do cavalo
// (limitações físicas e observações de saúde), oferecendo construtores nomeados
// e reexportando as telas individuais.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../application/controllers/horse_registration_controller.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../services/horse_image_selection_service.dart';
import 'horse_health_notes_screen.dart';
import 'horse_limitations_screen.dart';

export 'horse_health_notes_screen.dart';
export 'horse_limitations_screen.dart';

/// Tela configurável para anotações do cavalo (limitações físicas e saúde).
class HorseNotesScreen extends StatelessWidget {
  HorseNotesScreen.limitations({
    required HorseRegistrationDraft draft,
    HorseRegistrationRepository? repository,
    HorseMicrochipValidator? microchipValidator,
    HorseRegistrationController? controller,
    HorseImageSelectionService imageSelection = const HorseImageSelectionService(),
    HorseLimitationsCallback? onContinue,
    VoidCallback? onBack,
    Key? key,
  }) : this._(
         child: HorseLimitationsScreen(
           draft: draft,
           repository: repository,
           microchipValidator: microchipValidator,
           controller: controller,
           imageSelection: imageSelection,
           onContinue: onContinue,
           onBack: onBack,
           key: key,
         ),
         key: key,
       );

  HorseNotesScreen.health({
    required HorseRegistrationDraft draft,
    HorseRegistrationRepository? repository,
    HorseMicrochipValidator? microchipValidator,
    HorseRegistrationController? controller,
    HorseImageSelectionService imageSelection = const HorseImageSelectionService(),
    HorseHealthNotesCallback? onContinue,
    VoidCallback? onBack,
    Key? key,
  }) : this._(
         child: HorseHealthNotesScreen(
           draft: draft,
           repository: repository,
           microchipValidator: microchipValidator,
           controller: controller,
           imageSelection: imageSelection,
           onContinue: onContinue,
           onBack: onBack,
           key: key,
         ),
         key: key,
       );

  const HorseNotesScreen._({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
