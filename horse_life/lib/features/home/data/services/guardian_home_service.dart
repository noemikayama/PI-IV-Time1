// RESPONSÁVEL PELA DOCUMENTAÇÃO/INTEGRAÇÃO: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 25/10/2026
// Autor da documentação e integração: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização dos cabeçalhos e comentários explicativos das
// principais responsabilidades, regras e fluxos do módulo Guardian.
// -----------------------------------------------------------------------------
import '../models/guardian_home_data.dart';
import '../mappers/guardian_home_mapper.dart';
import '../repositories/guardian_repository.dart';

/// Orquestra a consulta ao repository e converte o retorno em dados de apresentação.
class GuardianHomeService {
  final GuardianRepository repository;
  GuardianHomeService(this.repository);

  Future<GuardianHomeData> fetchHome() async => (await repository.getHome())
      .toViewData(); // Traduz o contrato da API para a apresentação.
}
