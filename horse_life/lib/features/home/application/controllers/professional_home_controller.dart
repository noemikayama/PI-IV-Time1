// RESPONSÁVEL PELA IMPLEMENTAÇÃO FLUTTER: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Serviço de orquestração da Home do Profissional com Repository
// e Mapper, seguindo o padrão de GuardianHomeService.
// -----------------------------------------------------------------------------

// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Movido para application/controllers e passou a implementar HomeLoader.
// -----------------------------------------------------------------------------

import '../../data/models/professional_home_data.dart';
import '../../data/mappers/professional_home_mapper.dart';
import 'home_loader.dart';
import '../../data/repositories/professional_repository.dart';

/// Busca no repository e traduz a resposta da API para dados da interface.
class ProfessionalHomeController implements HomeLoader<ProfessionalHomeData> {
  final ProfessionalRepository repository;

  ProfessionalHomeController(this.repository);

  @override
  Future<ProfessionalHomeData> fetchHome() async =>
      (await repository.getHome()).toViewData();
}
