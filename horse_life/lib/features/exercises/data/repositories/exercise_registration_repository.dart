// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Atualização do contrato para retornar ExerciseRegistrationResult
// e exportação do modelo de resultado de cadastro.
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do contrato de persistência do cadastro de exercícios e da
// exceção tipada de domínio para apresentação segura de falhas na interface.
// -----------------------------------------------------------------------------

import '../../application/states/exercise_registration_draft.dart';
import '../models/exercise_registration_result.dart';

export '../models/exercise_registration_result.dart';

// Contrato que mantém os detalhes do Firebase Functions fora das telas.
abstract interface class ExerciseRegistrationRepository {
  // Envia o rascunho consolidado do exercício para persistência no backend.
  Future<ExerciseRegistrationResult> registerExercise({
    required ExerciseRegistrationDraft draft,
  });
}

// Erro seguro para apresentação na interface, sem expor detalhes internos da
// infraestrutura Firebase.
final class ExerciseRegistrationFailure implements Exception {
  const ExerciseRegistrationFailure(this.message);

  const ExerciseRegistrationFailure.connection()
    : message = 'Erro de conexão com o servidor';

  final String message;

  @override
  String toString() => message;
}
