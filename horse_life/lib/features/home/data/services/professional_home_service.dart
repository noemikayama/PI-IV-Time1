// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Adaptador temporário de compatibilidade com imports antigos.
// Novo código deve usar application/controllers/professional_home_controller.dart.
// -----------------------------------------------------------------------------

import '../../application/controllers/professional_home_controller.dart';
import '../repositories/professional_repository.dart';

@Deprecated('Use ProfessionalHomeController em application/controllers.')
class ProfessionalHomeService extends ProfessionalHomeController {
  ProfessionalHomeService(ProfessionalRepository repository) : super(repository);
}
