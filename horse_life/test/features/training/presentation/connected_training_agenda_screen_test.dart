// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Revisão dos comentários dos cenários e documentação dos dublês de
// agenda, carregamento da execução e finalização.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do teste de regressão da navegação semanal para garantir
// que o callback de setState não retorne Future; documentação do cenário e do
// carregador determinístico usado no teste. Cobertura da abertura da execução
// com todas as dependências obrigatórias do construtor.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';
import 'package:horse_life/features/training/data/models/training_execution_data.dart';
import 'package:horse_life/features/training/data/repositories/training_agenda_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_execution_repository.dart';
import 'package:horse_life/features/training/presentation/screens/connected_training_agenda_screen.dart';
import 'package:horse_life/features/training/presentation/screens/training_execution_screen.dart';

void main() {
  // Aciona a mesma seta usada na interface e captura exceções do framework para
  // detectar especificamente retornos assíncronos indevidos em setState.
  testWidgets('loads another week without returning a Future from setState', (
    tester,
  ) async {
    final loader = _FakeTrainingAgendaLoader();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConnectedTrainingAgendaScreen(loader: loader)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('agenda-next-week')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(loader.requestedDates, [null, DateTime(2026, 11, 25)]);
  });

  // Protege a composição Agenda → detalhes contra construtores incompletos e
  // valida a referência produzida a partir do treino e do plano selecionados.
  testWidgets('opens the execution screen with its required dependencies', (
    tester,
  ) async {
    final loader = _FakeTrainingAgendaLoader(includeTraining: true);
    final executionLoader = _FakeExecutionLoader();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConnectedTrainingAgendaScreen(
            loader: loader,
            executionLoader: executionLoader,
            completionSubmitter: const _FakeCompletionSubmitter(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Iniciar treino'));
    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TrainingExecutionScreen), findsOneWidget);
    expect(executionLoader.reference?.recordId, 'registro-1');
    expect(executionLoader.reference?.planId, 'plano-1');
  });
}

// Registra as datas solicitadas e responde imediatamente com uma semana fixa,
// isolando o teste de Firebase, rede e relógio.
class _FakeTrainingAgendaLoader implements TrainingAgendaLoader {
  _FakeTrainingAgendaLoader({this.includeTraining = false});

  final bool includeTraining;
  final requestedDates = <DateTime?>[];

  @override
  Future<TrainingAgendaData> fetchAgenda({DateTime? date}) {
    requestedDates.add(date);
    final training = TrainingAgendaEntry(
      id: 'registro-1',
      title: 'Trabalho de transições',
      horseName: 'Trovão',
      trainerName: 'Ana',
      planName: 'Condicionamento',
      date: DateTime(2026, 11, 18),
      durationMinutes: 45,
      status: TrainingAgendaStatus.planned,
      action: TrainingAgendaAction.start,
    );
    return Future.value(
      TrainingAgendaData(
        audience: TrainingAgendaAudience.guardian,
        today: DateTime(2026, 11, 18),
        weekStart: DateTime(2026, 11, 16),
        weekEnd: DateTime(2026, 11, 22),
        activePlansCount: includeTraining ? 1 : 0,
        plans: includeTraining
            ? [
                TrainingAgendaPlan(
                  id: 'plano-1',
                  trainingName: training.title,
                  horseName: training.horseName,
                  trainerName: training.trainerName,
                  planName: training.planName,
                  date: training.date,
                  status: training.status,
                ),
              ]
            : const [],
        weekTrainings: includeTraining ? [training] : const [],
        todayTrainings: includeTraining ? [training] : const [],
        history: const [],
      ),
    );
  }
}

// Captura a referência para verificar o mapeamento sem consultar as callables.
class _FakeExecutionLoader implements TrainingExecutionLoader {
  TrainingExecutionReference? reference;

  @override
  Future<TrainingExecutionData> fetchTraining(
    TrainingExecutionReference reference,
  ) async {
    this.reference = reference;
    return TrainingExecutionData(
      recordId: reference.recordId,
      title: reference.title,
      durationMinutes: reference.durationMinutes,
      description: 'Treino carregado pela navegação da agenda.',
      guidelines: const [],
      exercises: const [],
      isFinished: reference.isFinished,
    );
  }
}

// Satisfaz a dependência obrigatória da rota; o teste não finaliza a execução.
class _FakeCompletionSubmitter implements TrainingCompletionSubmitter {
  const _FakeCompletionSubmitter();

  @override
  Future<TrainingCompletionResult> submit(TrainingCompletionInput input) async {
    return const TrainingCompletionResult(status: 'REALIZADO');
  }
}
