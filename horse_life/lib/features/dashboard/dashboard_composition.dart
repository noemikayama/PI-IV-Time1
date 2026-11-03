// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Composição da fonte de dados do Dashboard para navegação autenticada.
// -----------------------------------------------------------------------------

import 'data/repositories/dashboard_repository.dart';
import 'data/repositories/firebase_dashboard_repository.dart';

/// Centraliza a criação do repository utilizado pelos Dashboards autenticados.
abstract final class DashboardComposition {
  static DashboardRepository production() => FirebaseDashboardRepository();
}
