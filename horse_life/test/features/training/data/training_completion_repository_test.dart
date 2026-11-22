// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão dos cenários de contrato da callable real para execução
// parcial e treino não realizado, com validação do payload e da resposta.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação e cobertura do contrato de
// registerTrainingExecution para treinos parciais e não realizados.
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
  // Impede regressão no nome público usado para localizar a Cloud Function.
  test('uses the callable exported by the executions backend', () {
    expect(
      FirebaseTrainingCompletionRepository.callableName,
      'registerTrainingExecution',
    );
  });

  // Exercita a fronteira completa: normalização dos textos, arredondamento do
  // tempo, estados dos exercícios e leitura do status devolvido pela callable.
  test(
    'serializes a partial execution for registerTrainingExecution',
    () async {
      Map<String, dynamic>? sent;
      final repository = FirebaseTrainingCompletionRepository(
        callable: (payload) async {
          sent = payload;
          return {
            'registro': {'status': 'PARCIAL'},
          };
        },
      );
      final result = await repository.submit(
        const TrainingCompletionInput(
          recordId: '66e1a0c2f1b2c3d4e5f6f103',
          elapsed: Duration(minutes: 12, seconds: 1),
          performancePerception: 8,
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
        'duracaoEfetiva': 13,
        'percepcaoDesempenho': 8,
        'dificuldades': 'Mão esquerda',
        'observacoes': ['Mais agitado no início'],
        'exercicios': [
          {'codigo': '12', 'realizacao': 'REALIZADO'},
          {'codigo': '13', 'realizacao': 'NAO_REALIZADO'},
        ],
      });
    },
  );

  // Garante a regra especial do backend para uma sessão sem exercício feito.
  test('omits performance fields when no exercise was completed', () async {
    Map<String, dynamic>? sent;
    final repository = FirebaseTrainingCompletionRepository(
      callable: (payload) async {
        sent = payload;
        return {
          'registro': {'status': 'NAO_REALIZADO'},
        };
      },
    );

    final result = await repository.submit(
      const TrainingCompletionInput(
        recordId: '66e1a0c2f1b2c3d4e5f6f103',
        elapsed: Duration(minutes: 4),
        performancePerception: null,
        difficulty: '',
        notes: 'Animal indisposto',
        exercises: [TrainingCompletionExercise(code: '12', completed: false)],
      ),
    );

    expect(result.status, 'NAO_REALIZADO');
    expect(sent, {
      'registroId': '66e1a0c2f1b2c3d4e5f6f103',
      'observacoes': ['Animal indisposto'],
      'exercicios': [
        {'codigo': '12', 'realizacao': 'NAO_REALIZADO'},
      ],
    });
  });
}
