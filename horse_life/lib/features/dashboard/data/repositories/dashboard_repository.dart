// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do getDashboard com contrato real e modo mock.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// -----------------------------------------------------------------------------

import '../models/dashboard_response.dart';

/// Contrato de consulta usado pelos painéis sem acoplar widgets ao Firebase.
abstract class DashboardRepository {
  Future<DashboardResponse> getDashboard({
    required String period,
    String? horseId,
    required bool professional,
  });
}
