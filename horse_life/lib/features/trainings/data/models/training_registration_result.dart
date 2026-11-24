// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modelo imutável de resultado do cadastro de
// treinamentos, contendo identificador, código sequencial gerado e título.
// -----------------------------------------------------------------------------

/// Representa a confirmação retornada pelo backend após o cadastro de um
/// treinamento.
final class TrainingRegistrationResult {
  const TrainingRegistrationResult({
    required this.id,
    required this.code,
    required this.title,
  });

  final String id;
  final int code;
  final String title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingRegistrationResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, code, title);
}
