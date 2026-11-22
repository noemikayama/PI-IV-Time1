// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Separa implementações de teste do contrato de produção.
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Expansão do contrato do repositório com consulta, edição e
// cancelamento do plano de treinamento, além do suporte local em memória.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do contrato do repositório de planos de treinamento
// (listagem da galeria por cavalo e cadastro do plano), exceções tipadas
// e implementação local para testes de widget e fluxo isolado.
// -----------------------------------------------------------------------------

import '../../application/states/training_plan_registration_draft.dart';
import '../models/training_plan_detail_data.dart';
import '../models/training_plan_gallery_item.dart';
import '../models/training_plan_registration_result.dart';

export '../models/training_plan_detail_data.dart';
export '../models/training_plan_registration_result.dart';

/// Contrato de acesso à galeria de treinamentos e operações do plano.
abstract interface class TrainingPlanRepository {
  /// Lista os treinamentos do treinador compatíveis com o cavalo informado.
  Future<List<TrainingPlanGalleryItem>> fetchTrainingGallery({
    required String horseId,
    String? searchQuery,
  });

  /// Envia o plano de treinamento consolidado para criação no backend.
  Future<TrainingPlanRegistrationResult> createTrainingPlan({
    required TrainingPlanRegistrationDraft draft,
  });

  /// Consulta os dados completos de um plano de treinamento para visualização.
  Future<TrainingPlanDetailData> getTrainingPlan(String planId);

  /// Atualiza os dados editados de um plano de treinamento existente.
  Future<TrainingPlanDetailData> updateTrainingPlan(
    String planId,
    TrainingPlanUpdate update,
  );

  /// Cancela um plano de treinamento ativo.
  Future<TrainingPlanDetailData> cancelTrainingPlan(String planId);
}

/// Erro seguro para apresentação na interface durante consultas à galeria.
final class TrainingPlanGalleryFailure implements Exception {
  const TrainingPlanGalleryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Erro seguro para apresentação na interface durante o cadastro do plano.
final class TrainingPlanRegistrationFailure implements Exception {
  const TrainingPlanRegistrationFailure(this.message);

  const TrainingPlanRegistrationFailure.connection()
    : message = 'Erro de conexão com o servidor';

  final String message;

  @override
  String toString() => message;
}

/// Erro seguro para apresentação na interface durante visualização, edição ou
/// cancelamento de planos de treinamento.
final class TrainingPlanDetailFailure implements Exception {
  const TrainingPlanDetailFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
