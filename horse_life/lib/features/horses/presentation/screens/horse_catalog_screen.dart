// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Tela unificada e modularizada de catálogo (raça e pelagem),
// oferecendo construtores nomeados e reexportando as telas individuais.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../application/controllers/horse_registration_controller.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../services/horse_image_selection_service.dart';
import 'horse_breed_screen.dart';
import 'horse_coat_screen.dart';

export 'horse_breed_screen.dart';
export 'horse_coat_screen.dart';

/// Tela configurável para as etapas baseadas em catálogo de pesquisa (raça e pelagem).
class HorseCatalogScreen extends StatelessWidget {
  HorseCatalogScreen.breed({
    required HorseRegistrationDraft draft,
    HorseRegistrationRepository? repository,
    HorseMicrochipValidator? microchipValidator,
    HorseRegistrationController? controller,
    HorseImageSelectionService imageSelection = const HorseImageSelectionService(),
    HorseBreedCallback? onContinue,
    VoidCallback? onBack,
    Key? key,
  }) : this._(
         child: HorseBreedScreen(
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

  HorseCatalogScreen.coat({
    required HorseRegistrationDraft draft,
    HorseRegistrationRepository? repository,
    HorseMicrochipValidator? microchipValidator,
    HorseRegistrationController? controller,
    HorseImageSelectionService imageSelection = const HorseImageSelectionService(),
    HorseCoatCallback? onContinue,
    VoidCallback? onBack,
    Key? key,
  }) : this._(
         child: HorseCoatScreen(
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

  const HorseCatalogScreen._({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
