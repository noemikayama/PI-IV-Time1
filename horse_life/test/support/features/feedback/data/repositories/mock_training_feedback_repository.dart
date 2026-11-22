// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Retorno do registro atualizado, alinhado ao contrato das callables.
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Isolamento da massa de dados mock em data/mocks para reduzir
// responsabilidades deste repositório.
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação do contrato TrainingFeedbackRepository para permitir
// troca futura do mock pela persistência remota sem alterar as telas.
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Simulação em memória de registros de execução e cadastro de
// feedback, com cenários de feedback ausente/presente e sem acesso ao Firebase.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/training/data/models/training_agenda_data.dart';

import '../mocks/training_feedback_mock_data.dart';
import 'package:horse_life/features/feedback/data/models/training_execution_record.dart';
import 'package:horse_life/features/feedback/data/repositories/training_feedback_repository.dart';

/// Repositório estritamente MOCK. Nada é enviado para Cloud Functions.
/// O singleton preserva o feedback durante a navegação da sessão atual.
class MockTrainingFeedbackRepository implements TrainingFeedbackRepository {
  MockTrainingFeedbackRepository._() {
    reset();
  }

  static final MockTrainingFeedbackRepository instance =
      MockTrainingFeedbackRepository._();

  final Map<String, TrainingExecutionRecord> _records = {};

  @override
  TrainingExecutionRecord? findById(String id) => _records[id];

  List<TrainingExecutionRecord> get demoRecords => [
    _records['feedback-demo-pendente']!,
    _records['feedback-demo-registrado']!,
  ];

  /// Restaura o cenário visual original em testes e na entrada da demo.
  void reset() {
    _records.clear();
    for (final record in TrainingFeedbackMockData.initialRecords()) {
      _records[record.id] = record;
    }
  }

  /// Adapta um item da agenda à prévia visual do histórico. A agenda ainda
  /// não expõe os relatos detalhados, então estes vêm de dados demonstrativos.
  TrainingExecutionRecord fromAgenda(TrainingAgendaEntry entry) {
    final cached = _records[entry.id];
    if (cached != null) return cached;
    final record = TrainingFeedbackMockData.fromAgenda(entry);
    _records[record.id] = record;
    return record;
  }

  /// A simulação permite um feedback por execução; o responsável não grava.
  @override
  TrainingExecutionRecord registerFeedback({
    required String recordId,
    required TrainingExecutionFeedback feedback,
  }) {
    final record = _records[recordId];
    if (record == null) {
      throw StateError('Registro de execução não encontrado.');
    }
    if (record.feedback != null) {
      throw StateError('Este treino já possui um feedback registrado.');
    }
    final updated = record.withFeedback(feedback);
    _records[recordId] = updated;
    return updated;
  }
}
