// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - RA 25016900
// Alteração: Validador de produção do microchip passa a consultar o servidor
// Java, pela callable validateMicrochip.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Inclusão do método de fábrica productionController para instanciar
// o controlador com repositório e validador de microchip de produção ou injetados.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Ponto único para escolher o backend e a validação do microchip.
// -----------------------------------------------------------------------------

import 'application/controllers/horse_registration_controller.dart';
import 'data/models/horse_registration_draft.dart';
import 'data/repositories/firebase_horse_registration_repository.dart';
import 'data/repositories/horse_microchip_validator.dart';
import 'data/repositories/horse_registration_repository.dart';
import 'data/repositories/remote_horse_microchip_validator.dart';
import 'data/services/firebase_horse_registration_service.dart';

/// Ponto único de composição para criar os serviços, validadores e controlador.
abstract final class HorseRegistrationComposition {
  static HorseRegistrationRepository productionRepository() =>
      FirebaseHorseRegistrationRepository();

  // O formato é conferido no app; o país e os dígitos verificadores, no
  // servidor Java, pela callable validateMicrochip.
  static HorseMicrochipValidator productionMicrochipValidator() =>
      RemoteHorseMicrochipValidator(
        verifyOnServer: FirebaseHorseRegistrationService().validateMicrochip,
      );

  /// Cria o controlador de cadastro com as dependências padrão ou substituídas.
  static HorseRegistrationController productionController({
    HorseRegistrationRepository? repository,
    HorseMicrochipValidator? microchipValidator,
    HorseRegistrationDraft? initialDraft,
  }) => HorseRegistrationController(
    repository: repository ?? productionRepository(),
    microchipValidator:
        microchipValidator ?? productionMicrochipValidator(),
    initialDraft: initialDraft,
  );
}
