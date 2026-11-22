// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Manutenção da fonte local como fallback para usos isolados após a
// inclusão do adapter remoto no fluxo profissional.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Padronização do contrato e do arquivo com o termo sport.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do contrato assíncrono para consulta das modalidades e da
// fonte local temporária usada até a integração com a Firebase Function.
// -----------------------------------------------------------------------------


import 'package:horse_life/features/authentication/data/repositories/training_sport_repository.dart';

// Fonte local usada como fallback em usos isolados e testes de apresentação.
class LocalTrainingSportRepository implements TrainingSportRepository {
  const LocalTrainingSportRepository();

  @override
  Future<List<String>> fetchSports() async {
    return const ['Adestramento', 'Salto', 'Enduro'];
  }
}
