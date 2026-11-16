// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modelo de resultado do cadastro de exercícios,
// contendo identificador, código gerado, nome e aviso de falhas em mídias.
// -----------------------------------------------------------------------------

final class ExerciseRegistrationResult {
  const ExerciseRegistrationResult({
    required this.id,
    required this.code,
    required this.name,
    this.warning,
    this.failedMediaCount = 0,
  });

  final String id;
  final int code;
  final String name;
  final String? warning;
  final int failedMediaCount;

  bool get hasMediaWarning => failedMediaCount > 0 && warning != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseRegistrationResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          name == other.name &&
          warning == other.warning &&
          failedMediaCount == other.failedMediaCount;

  @override
  int get hashCode => Object.hash(id, code, name, warning, failedMediaCount);
}
