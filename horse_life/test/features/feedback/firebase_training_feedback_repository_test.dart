// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Testes do contrato de consulta, envio e permissões da API.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/feedback/data/models/training_execution_record.dart';
import 'package:horse_life/features/feedback/data/models/training_record_mapper.dart';
import 'package:horse_life/features/feedback/data/repositories/firebase_training_feedback_repository.dart';

const id = '507f1f77bcf86cd799439011';

Map<String, dynamic> response({bool saved = false, bool allowed = true, bool executed = true}) => {
  'role': 'TREINADOR',
  'registro': {'id': id, 'codigo': 1, 'status': 'PARCIAL', 'dataPlanejada': '2026-11-21'},
  'plano': {'id': id, 'titulo': 'Plano', 'objetivo': 'Equilíbrio'},
  'treinamento': {'codigo': '1', 'titulo': 'Treino', 'descricao': '', 'orientacoes': [], 'duracaoEstimada': 45},
  'cavalo': {'id': id, 'nome': 'Apollo'},
  'treinador': {'nome': 'Treinador'},
  'atleta': null,
  'exercicios': [],
  'execucao': executed ? {
    'dataExecucao': null, 'duracaoEfetiva': 35, 'percepcaoDesempenho': 7,
    'dificuldades': 'Equilíbrio', 'observacoes': ['Primeira', 'Segunda'],
    'exerciciosRealizados': 2, 'exerciciosNaoRealizados': 1,
  } : null,
  'feedback': saved ? {'data': '2026-11-22T15:00:00Z', 'comentario': 'Bom', 'dificuldadesIdentificadas': ['Postura'], 'orientacoes': []} : null,
  'permissoes': {'podeRegistrarFeedback': allowed && !saved, 'podeRegistrarExecucao': false},
};

void main() {
  test('consulta pelo registroId e preserva campos nulos', () async {
    final repository = FirebaseTrainingFeedbackRepository(callable: (name, payload) async {
      expect(name, 'getTrainingRecord');
      expect(payload, {'registroId': id});
      return response();
    });
    final record = await repository.findById(id);
    expect(record.executedAt, isNull);
    expect(record.durationMinutes, 35);
    expect(record.performancePerception, '7/10');
    expect(record.observations, 'Primeira\nSegunda');
    expect(record.canRegisterFeedback, isTrue);
  });

  test('envia apenas campos aceitos e usa data devolvida pelo backend', () async {
    final repository = FirebaseTrainingFeedbackRepository(callable: (name, payload) async {
      expect(name, 'registerTrainingFeedback');
      expect(payload, {'registroId': id, 'comentario': 'Bom', 'dificuldadesIdentificadas': ['Postura'], 'orientacoes': []});
      return response(saved: true);
    });
    final updated = await repository.registerFeedback(recordId: id, feedback: TrainingExecutionFeedback(
      createdAt: DateTime(2000), comment: ' Bom ', difficulties: ['Postura'], guidelines: [],
    ));
    expect(updated.feedback?.createdAt.toUtc(), DateTime.utc(2026, 11, 22, 15));
    expect(updated.canRegisterFeedback, isFalse);
  });

  test('não permite escrita sem permissão ou sem relato', () {
    expect(TrainingRecordMapper.fromResponse(response(allowed: false)).canRegisterFeedback, isFalse);
    final missing = TrainingRecordMapper.fromResponse(response(executed: false));
    expect(missing.canRegisterFeedback, isFalse);
    expect(missing.hasExecution, isFalse);
    expect(missing.durationMinutes, isNull);
  });
}
