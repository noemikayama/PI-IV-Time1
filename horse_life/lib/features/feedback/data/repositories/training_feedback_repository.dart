// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Contrato assíncrono compatível com a fonte remota e o mock em memória.
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Extração do contrato de consulta e cadastro de feedback para
// desacoplar as telas da implementação mockada e facilitar a futura API.
// -----------------------------------------------------------------------------

import 'dart:async';

import '../models/training_execution_record.dart';

/// Contrato utilizado pelas telas, sem conhecimento sobre Firebase ou mocks.
abstract class TrainingFeedbackRepository {
  FutureOr<TrainingExecutionRecord?> findById(String recordId);

  /// Registra um feedback para uma execução que ainda não foi avaliada.
  /// Retorna o registro confirmado pela fonte de dados.
  FutureOr<TrainingExecutionRecord> registerFeedback({
    required String recordId,
    required TrainingExecutionFeedback feedback,
  });
}
