// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração da Cloud Function getDashboard.
//
// Data: 01/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Correção da região da Function para southamerica-east1
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'dashboard_repository.dart';
import '../models/dashboard_response.dart';

/// Implementação Firebase Callable da consulta getDashboard em São Paulo.
class FirebaseDashboardRepository implements DashboardRepository {
  FirebaseDashboardRepository({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFunctions _functions;

  @override
  Future<DashboardResponse> getDashboard({
    required String period,
    String? horseId,
    required bool professional,
  }) async {
    try {
      final response = await _functions
          .httpsCallable('getDashboard')
          .call(<String, dynamic>{
            'periodo': period,
            'cavaloId': professional ? null : horseId,
            'painelProfissional': professional,
          });
      return DashboardResponse(DashboardResponse.normalize(response.data));
    } on FirebaseFunctionsException catch (error) {
      // Mensagens úteis durante o desenvolvimento; remover/restringir
      // quando a integração estiver estabilizada.
      assert(() {
        // ignore: avoid_print
        print('getDashboard falhou: ${error.code} - ${error.message}');
        return true;
      }());
      rethrow;
    }
  }
}
