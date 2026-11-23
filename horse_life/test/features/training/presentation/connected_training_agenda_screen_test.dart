// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura da abertura de TrainingExecutionRecordScreen ao tocar
// no card do histórico de execuções da agenda.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Ajuste dos testes para verificar a abertura de TrainingDetailScreen
// (e não TrainingExecutionScreen) ao tocar em "Ver detalhes", além de validar
// o repasse para onViewTraining customizado.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Verificação da recarga da semana depois do retorno da tela de
// detalhes, mantendo a agenda sincronizada com o registro da execução.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Teste verificando a abertura da tela de execução ao tocar em
// "Ver detalhes" no card semanal quando onViewTraining não é fornecido externamente.
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
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/feedback/presentation/screens/training_execution_record_screen.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';
import 'package:horse_life/features/training/data/models/training_execution_data.dart';
import 'package:horse_life/features/training/data/repositories/training_agenda_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_execution_repository.dart';
import 'package:horse_life/features/training/presentation/screens/connected_training_agenda_screen.dart';
import 'package:horse_life/features/training/presentation/screens/training_execution_screen.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_detail_screen.dart';

import '../../../support/features/feedback/data/repositories/mock_training_feedback_repository.dart';

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

    await tester.tap(find.byKey(const Key('training-execution-back')));
    await tester.pumpAndSettle();

    expect(loader.requestedDates, [null, DateTime(2026, 11, 16)]);
  });

  // Garante que o botão "Ver detalhes" sob o calendário abre a tela de visualização
  // padrão (TrainingDetailScreen) e não a de execução, preservando restrições de perfil.
  testWidgets(
    'opens training detail screen when tapping Ver detalhes under weekly calendar',
    (tester) async {
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

      await tester.ensureVisible(find.text('Ver detalhes'));
      await tester.tap(find.text('Ver detalhes'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TrainingDetailScreen), findsOneWidget);
      expect(find.byType(TrainingExecutionScreen), findsNothing);
    },
  );

  testWidgets(
    'forwards to custom onViewTraining when tapping Ver detalhes under calendar',
    (tester) async {
      final loader = _FakeTrainingAgendaLoader(includeTraining: true);
      TrainingAgendaEntry? viewedTraining;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectedTrainingAgendaScreen(
              loader: loader,
              onViewTraining: (entry) => viewedTraining = entry,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Ver detalhes'));
      await tester.tap(find.text('Ver detalhes'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(viewedTraining?.id, 'registro-1');
    },
  );

  testWidgets(
    'opens training execution record screen when tapping a history card',
    (tester) async {
      final loader = _FakeTrainingAgendaLoader(includeHistory: true);
      final feedbackRepository = MockTrainingFeedbackRepository.instance;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ConnectedTrainingAgendaScreen(
              loader: loader,
              feedbackRepository: feedbackRepository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Trabalho de transições'));
      await tester.tap(find.text('Trabalho de transições'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TrainingExecutionRecordScreen), findsOneWidget);
    },
  );
}

// Registra as datas solicitadas e responde imediatamente com uma semana fixa,
// isolando o teste de Firebase, rede e relógio.
class _FakeTrainingAgendaLoader implements TrainingAgendaLoader {
  _FakeTrainingAgendaLoader({
    this.includeTraining = false,
    this.includeHistory = false,
  });

  final bool includeTraining;
  final bool includeHistory;
  final requestedDates = <DateTime?>[];

  @override
  Future<TrainingAgendaData> fetchAgenda({DateTime? date}) {
    requestedDates.add(date);
    final training = TrainingAgendaEntry(
      id: includeHistory ? 'feedback-demo-pendente' : 'registro-1',
      title: 'Trabalho de transições',
      horseName: 'Trovão',
      trainerName: 'Ana',
      planName: 'Condicionamento',
      date: DateTime(2026, 11, 18),
      durationMinutes: 45,
      status: includeHistory
          ? TrainingAgendaStatus.completed
          : TrainingAgendaStatus.planned,
      action: includeHistory
          ? TrainingAgendaAction.view
          : TrainingAgendaAction.start,
    );
    return Future.value(
      TrainingAgendaData(
        audience: TrainingAgendaAudience.guardian,
        today: DateTime(2026, 11, 18),
        weekStart: DateTime(2026, 11, 16),
        weekEnd: DateTime(2026, 11, 22),
        activePlansCount: (includeTraining || includeHistory) ? 1 : 0,
        plans: (includeTraining || includeHistory)
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
        history: includeHistory ? [training] : const [],
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
