// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento de documentação das interfaces e implementações de
// repositório de visualização e edição de treinamentos.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do contrato TrainingDetailRepository, exceção de domínio
// TrainingDetailFailure e implementação em memória LocalTrainingDetailRepository.
// -----------------------------------------------------------------------------

import '../../../training_plans/data/models/training_plan_gallery_item.dart';
import '../mocks/mock_training_detail.dart';
import '../models/training_detail_data.dart';

/// Falha controlada durante consulta ou edição dos detalhes de um treinamento.
///
/// Encapsula erros de negócio e de comunicação ocorridos durante as chamadas
/// às Cloud Functions ou validações de domínio da aplicação.
final class TrainingDetailFailure implements Exception {
  const TrainingDetailFailure(this.message);

  final String message;

  @override
  String toString() => 'TrainingDetailFailure: $message';
}

/// Contrato de acesso aos detalhes e edição de um treinamento.
///
/// Define as operações obrigatórias para consulta e atualização dos dados
/// de treinamentos cadastrados no sistema.
abstract interface class TrainingDetailRepository {
  /// Consulta os detalhes completos de um treinamento a partir de seu código.
  ///
  /// O [trainingCode] representa o código numérico sequencial do treinamento.
  /// Caso seja fornecido um [fallbackTraining], este pode ser utilizado para
  /// complementar dados ausentes ou servir de fallback seguro em ambientes locais.
  Future<TrainingDetailData> getTrainingDetails(
    String trainingCode, {
    TrainingPlanGalleryItem? fallbackTraining,
  });

  /// Envia as alterações validadas de um treinamento existente.
  ///
  /// Atualiza título, descrição, duração estimada, orientações e lista de exercícios.
  Future<TrainingDetailData> updateTraining(
    String trainingCode,
    TrainingUpdate update,
  );
}

/// Implementação local em memória para testes isolados e visualização offline.
///
/// Permite simular o ciclo completo de consulta e persistência de alterações sem
/// dependência de rede ou dos serviços do Firebase.
class LocalTrainingDetailRepository implements TrainingDetailRepository {
  LocalTrainingDetailRepository({
    TrainingDetailData? initialTraining,
    this.role = TrainingViewerRole.trainer,
  }) : _currentTraining = initialTraining;

  TrainingDetailData? _currentTraining;
  final TrainingViewerRole role;

  @override
  Future<TrainingDetailData> getTrainingDetails(
    String trainingCode, {
    TrainingPlanGalleryItem? fallbackTraining,
  }) async {
    return _currentTraining ??= MockTrainingDetail.buildDefault(
      trainingCode: trainingCode,
      initialTraining: fallbackTraining,
      role: role,
    );
  }

  @override
  Future<TrainingDetailData> updateTraining(
    String trainingCode,
    TrainingUpdate update,
  ) async {
    final base = await getTrainingDetails(trainingCode);
    final updated = update.applyTo(base);
    _currentTraining = updated;
    return updated;
  }
}
