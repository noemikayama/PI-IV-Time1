// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do cenário, dados de entrada e limites verificados na
// serialização e resposta da finalização.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do teste da finalização para validar a serialização do
// formulário e a conversão da resposta de finishTraining.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';

void main() {
  // Exercita a fronteira completa: normalização dos textos, arredondamento do
  // tempo, estados dos exercícios e leitura do status devolvido pela callable.
  test('serializes the execution form for finishTraining', () async {
    Map<String, dynamic>? sent;
    final repository = FirebaseTrainingCompletionRepository(
      callable: (payload) async {
        sent = payload;
        return {'status': 'PARCIAL'};
      },
    );
    final result = await repository.submit(
      const TrainingCompletionInput(
        recordId: '66e1a0c2f1b2c3d4e5f6f103',
        elapsed: Duration(minutes: 12, seconds: 1),
        performancePerception: ' Boa evolução ',
        difficulty: ' Mão esquerda ',
        notes: ' Mais agitado no início ',
        exercises: [
          TrainingCompletionExercise(code: '12', completed: true),
          TrainingCompletionExercise(code: '13', completed: false),
        ],
      ),
    );

    expect(result.status, 'PARCIAL');
    expect(sent, {
      'registroId': '66e1a0c2f1b2c3d4e5f6f103',
      'duracaoEfetivaMinutos': 13,
      'percepcaoDesempenho': 'Boa evolução',
      'dificuldade': 'Mão esquerda',
      'observacoes': ['Mais agitado no início'],
      'exercicios': [
        {'codigo': '12', 'realizacao': 'REALIZADO'},
        {'codigo': '13', 'realizacao': 'NAO_REALIZADO'},
      ],
    });
  });
}
