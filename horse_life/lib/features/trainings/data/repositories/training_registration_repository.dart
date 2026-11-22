// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Separa implementações de teste do contrato de produção.
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação defensiva exigindo ao menos uma orientação e duração
// estimada não inferior à soma dos exercícios selecionados.
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do contrato de persistência e cálculo de duração de
// treinamentos, exceção tipada de domínio e implementação local para testes.
// -----------------------------------------------------------------------------

import '../../application/states/training_registration_draft.dart';
import '../models/training_exercise_item.dart';
import '../models/training_registration_result.dart';

export '../models/training_registration_result.dart';

/// Contrato que mantém os detalhes das Cloud Functions fora das telas de
/// cadastro de treinamentos.
abstract interface class TrainingRegistrationRepository {
  /// Calcula a soma das durações padrão dos exercícios selecionados.
  Future<int> sumExerciseDurations({
    required List<TrainingExerciseItem> exercises,
  });

  /// Envia o rascunho consolidado do treinamento para persistência no backend.
  Future<TrainingRegistrationResult> registerTraining({
    required TrainingRegistrationDraft draft,
  });
}

/// Erro seguro para apresentação na interface durante operações de treinamento.
final class TrainingRegistrationFailure implements Exception {
  const TrainingRegistrationFailure(this.message);

  const TrainingRegistrationFailure.connection()
    : message = 'Erro de conexão com o servidor';

  final String message;

  @override
  String toString() => message;
}
