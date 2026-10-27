// RESPONSÁVEL PELA IMPLEMENTAÇÃO FLUTTER: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Repositório com callable getHome e injeção de dependência,
// espelhando a arquitetura do Guardian. Contrato Professional pendente de validação.
// -----------------------------------------------------------------------------
import 'package:cloud_functions/cloud_functions.dart';
import '../models/professional_model.dart';

/// Abstração para teste e troca futura da origem de dados.
abstract class ProfessionalRepository {
  Future<ProfessionalHomeModel> getHome();
}

/// Usa a MESMA região e callable getHome da implementação do Guardian.
/// Requer Firebase inicializado, autenticação e suporte do backend ao papel.
class FirebaseProfessionalRepository implements ProfessionalRepository {
  final FirebaseFunctions _functions;

  FirebaseProfessionalRepository({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  @override
  Future<ProfessionalHomeModel> getHome() async {
    final response = await _functions.httpsCallable('getHome').call<dynamic>(
      <String, dynamic>{},
    );
    if (response.data is! Map) {
      throw const FormatException('Resposta inválida da Cloud Function getHome.');
    }
    return ProfessionalHomeModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
