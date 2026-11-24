// RESPONSÁVEL PELA DOCUMENTAÇÃO/INTEGRAÇÃO: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 25/10/2026
// Autor da documentação e integração: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização dos cabeçalhos e comentários explicativos das
// principais responsabilidades, regras e fluxos do módulo Guardian.
// -----------------------------------------------------------------------------

// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Movido para application/controllers e passou a implementar HomeLoader.
// -----------------------------------------------------------------------------

import '../../data/models/guardian_home_data.dart';
import '../../data/mappers/guardian_home_mapper.dart';
import 'home_loader.dart';
import '../../data/repositories/guardian_repository.dart';

/// Orquestra a consulta ao repository e converte o retorno em dados de apresentação.
class GuardianHomeController implements HomeLoader<GuardianHomeData> {
  final GuardianRepository repository;
  GuardianHomeController(this.repository);

  @override
  Future<GuardianHomeData> fetchHome() async =>
      (await repository.getHome()).toViewData(); // Traduz o contrato da API para a apresentação.
}
