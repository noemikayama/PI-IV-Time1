// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação das callables falsas e das asserções do carregamento
// consolidado de treino, exercício, materiais e mídias.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do teste do carregamento completo para validar a resolução
// do treino no plano e o mapeamento dos detalhes e recursos dos exercícios.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';
import 'package:horse_life/features/training/data/models/training_execution_data.dart';
import 'package:horse_life/features/training/data/repositories/training_execution_repository.dart';

void main() {
  // As três callables falsas reproduzem plano, treinamento e exercício para
  // verificar tanto os payloads quanto o modelo consolidado entregue à tela.
  test('resolves the scheduled code and maps the complete training', () async {
    Map<String, dynamic>? planPayload;
    Map<String, dynamic>? trainingPayload;
    final repository = FirebaseTrainingExecutionRepository(
      getPlanDetails: (payload) async {
        planPayload = payload;
        return {
          'todosOsTreinos': {
            'treinos': [
              {
                'data': '2026-11-21',
                'treinamento': {
                  'codigo': '42',
                  'titulo': 'Trabalho de transições',
                },
              },
            ],
          },
        };
      },
      getTrainingDetails: (payload) async {
        trainingPayload = payload;
        return {
          'titulo': 'Trabalho de transições',
          'descricao': 'Sessão focada em equilíbrio.',
          'duracaoEstimada': 45,
          'orientacoes': ['Encerrar com 5 minutos de passo.'],
          'exercicios': [
            {
              'codigo': '12',
              'nome': 'Aquecimento ao passo',
              'duracao': 10,
              'descricao': 'Caminhada em pista.',
            },
          ],
        };
      },
      getExercise: (payload) async => {
        'orientacoes': ['Manter contato leve com as rédeas.'],
        'materiais': [
          {'descricao': 'Cavalete', 'quantidade': 3},
        ],
        'imagens': [
          {'url': 'https://example.com/image.jpg'},
        ],
        'videos': [
          {'url': 'https://example.com/video.mp4'},
        ],
      },
    );

    final result = await repository.fetchTraining(
      TrainingExecutionReference(
        recordId: 'registro-1',
        planId: 'plano-1',
        title: 'Trabalho de transições',
        date: DateTime(2026, 11, 21),
        durationMinutes: 45,
        status: TrainingAgendaStatus.completed,
      ),
    );

    expect(planPayload, {'planoId': 'plano-1'});
    expect(trainingPayload, {'codigo': '42'});
    expect(result.recordId, 'registro-1');
    expect(result.isFinished, isTrue);
    expect(result.guidelines, ['Encerrar com 5 minutos de passo.']);
    expect(result.exercises.single.name, 'Aquecimento ao passo');
    expect(result.exercises.single.guidelines, [
      'Manter contato leve com as rédeas.',
    ]);
    expect(result.exercises.single.materials.single.quantity, 3);
    expect(result.exercises.single.media.length, 2);
  });
}
