// RESPONSÁVEL PELA IMPLEMENTAÇÃO FLUTTER: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Serviço de orquestração da Home do Profissional com Repository
// e Mapper, seguindo o padrão de GuardianHomeService.
// -----------------------------------------------------------------------------
import '../models/professional_home_data.dart';
import '../mappers/professional_home_mapper.dart';
import '../repositories/professional_repository.dart';

/// Busca no repository e traduz a resposta da API para dados da interface.
class ProfessionalHomeService {
  final ProfessionalRepository repository;

  ProfessionalHomeService(this.repository);

  Future<ProfessionalHomeData> fetchHome() async =>
      (await repository.getHome()).toViewData();
}
