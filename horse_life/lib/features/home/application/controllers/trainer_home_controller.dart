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

import '../../data/models/trainer_home_data.dart';
import '../../data/mappers/trainer_home_mapper.dart';
import 'home_loader.dart';
import '../../data/repositories/trainer_repository.dart';

/// Busca no repository e traduz a resposta da API para dados da interface.
class TrainerHomeController implements HomeLoader<TrainerHomeData> {
  final TrainerRepository repository;

  TrainerHomeController(this.repository);

  @override
  Future<TrainerHomeData> fetchHome() async =>
      (await repository.getHome()).toViewData();
}
