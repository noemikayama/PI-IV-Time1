// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Ponto único para escolher o backend e a validação do microchip.
// -----------------------------------------------------------------------------

import 'data/repositories/firebase_horse_registration_repository.dart';
import 'data/repositories/horse_microchip_validator.dart';
import 'data/repositories/horse_registration_repository.dart';

/// Para mudar o servidor no futuro, altere esta composição e o adaptador.
/// A Home, a tela e os mocks de raças/pelagens não precisam mudar.
abstract final class HorseRegistrationComposition {
  static HorseRegistrationRepository productionRepository() =>
      FirebaseHorseRegistrationRepository();

  // Quando o Java estiver disponível, injete aqui o validador da API Java.
  static HorseMicrochipValidator productionMicrochipValidator() =>
      const LocalHorseMicrochipValidator();
}
