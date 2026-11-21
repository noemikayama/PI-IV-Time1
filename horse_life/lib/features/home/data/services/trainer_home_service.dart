// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Adaptador temporário de compatibilidade com imports antigos.
// Novo código deve usar application/controllers/trainer_home_controller.dart.
// -----------------------------------------------------------------------------

import '../../application/controllers/trainer_home_controller.dart';
import '../repositories/trainer_repository.dart';

@Deprecated('Use TrainerHomeController em application/controllers.')
class TrainerHomeService extends TrainerHomeController {
  TrainerHomeService(TrainerRepository repository) : super(repository);
}
