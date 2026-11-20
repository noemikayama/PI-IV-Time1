// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modelo imutável de resultado do cadastro de planos
// de treinamento, contendo identificador, código, status, datas e quantidade
// de registros planejados gerados.
// -----------------------------------------------------------------------------

/// Representa a confirmação retornada pelo backend após o cadastro de um plano
/// de treinamento.
final class TrainingPlanRegistrationResult {
  const TrainingPlanRegistrationResult({
    required this.id,
    required this.code,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.generatedRecordsCount,
  });

  final String id;
  final int code;
  final String status;
  final String startDate;
  final String endDate;
  final int generatedRecordsCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingPlanRegistrationResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          status == other.status &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          generatedRecordsCount == other.generatedRecordsCount;

  @override
  int get hashCode => Object.hash(
    id,
    code,
    status,
    startDate,
    endDate,
    generatedRecordsCount,
  );
}
