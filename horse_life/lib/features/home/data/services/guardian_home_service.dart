// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Adaptador temporário de compatibilidade com imports antigos.
// Novo código deve usar application/controllers/guardian_home_controller.dart.
// -----------------------------------------------------------------------------

import '../../application/controllers/guardian_home_controller.dart';
import '../repositories/guardian_repository.dart';

@Deprecated('Use GuardianHomeController em application/controllers.')
class GuardianHomeService extends GuardianHomeController {
  GuardianHomeService(GuardianRepository repository) : super(repository);
}
