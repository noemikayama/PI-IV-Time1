// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Adoção de super parâmetro no adaptador legado e remoção do import
// tornado desnecessário, mantendo a compatibilidade com o controlador.
//
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Adaptador temporário de compatibilidade com imports antigos.
// Novo código deve usar application/controllers/guardian_home_controller.dart.
// -----------------------------------------------------------------------------

import '../../application/controllers/guardian_home_controller.dart';

@Deprecated('Use GuardianHomeController em application/controllers.')
class GuardianHomeService extends GuardianHomeController {
  GuardianHomeService(super.repository);
}
