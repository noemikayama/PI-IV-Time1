// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Extração do contrato de consulta e cadastro de feedback para
// desacoplar as telas da implementação mockada e facilitar a futura API.
// -----------------------------------------------------------------------------

import '../models/training_execution_record.dart';

/// Contrato utilizado pelas telas, sem conhecimento sobre Firebase ou mocks.
abstract class TrainingFeedbackRepository {
  TrainingExecutionRecord? findById(String recordId);

  /// Registra um feedback para uma execução que ainda não foi avaliada.
  /// Lança [StateError] quando o registro não existe ou já tem feedback.
  void registerFeedback({
    required String recordId,
    required TrainingExecutionFeedback feedback,
  });
}
