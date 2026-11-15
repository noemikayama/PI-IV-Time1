// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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

/// Ponto único de composição para criar os serviços, validadores e controlador.
abstract final class HorseRegistrationComposition {
  static HorseRegistrationRepository productionRepository() =>
      FirebaseHorseRegistrationRepository();

  // Quando o Java estiver disponível, injete aqui o validador da API Java.
  static HorseMicrochipValidator productionMicrochipValidator() =>
      const LocalHorseMicrochipValidator();

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
