// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do modo somente leitura, que exibe os detalhes sem a
// ação de iniciar a execução do treinamento.
// 
// Data: 22/11/2026
// Alteração: Cobertura da atualização e do bloqueio da ação principal depois
// que o formulário de conclusão confirma o registro do treino.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação da fábrica da tela, dos estados ativo/finalizado e dos
// dublês usados para carregar e concluir o treino.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura dos detalhes da execução, do início do treino e do estado
// desabilitado apresentado para registros já finalizados.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';
import 'package:horse_life/features/training/data/models/training_execution_data.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_execution_repository.dart';
import 'package:horse_life/features/training/presentation/screens/training_execution_screen.dart';

void main() {
  // Constrói a tela nos dois estados possíveis usando dependências determinísticas.
  Widget buildScreen({required bool finished, bool canStart = true}) =>
      MaterialApp(
        theme: AppTheme.light,
        home: TrainingExecutionScreen(
          loader: _FakeExecutionLoader(finished: finished),
          completionSubmitter: const _FakeCompletionSubmitter(),
          reference: TrainingExecutionReference(
            recordId: 'registro-1',
            planId: 'plano-1',
            title: 'Trabalho de transições',
            date: DateTime(2026, 11, 21),
            durationMinutes: 45,
            status: finished
                ? TrainingAgendaStatus.completed
                : TrainingAgendaStatus.planned,
            canStart: canStart,
          ),
        ),
      );

  // Um registro planejado apresenta detalhes e permite avançar à execução ativa.
  testWidgets('renders the prototype content and active start state', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen(finished: false));
    await tester.pumpAndSettle();

    expect(find.text('Trabalho de transições'), findsOneWidget);
    expect(find.text('Orientações:'), findsOneWidget);
    expect(find.text('Aquecimento ao passo'), findsOneWidget);
    final duration = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(const Key('training-duration-text')),
        matching: find.byType(RichText),
      ),
    );
    final description = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(const Key('training-description-text')),
        matching: find.byType(RichText),
      ),
    );
    final guidelinesTitle = tester.widget<Text>(
      find.byKey(const Key('training-guidelines-title')),
    );
    final guideline = tester.widget<Text>(
      find.text('Encerrar com 5 minutos de passo.'),
    );
    expect(duration.text.style?.fontSize, 18);
    expect(description.text.style?.fontSize, 18);
    expect(
      _spanStartingWith(duration.text, 'Duração estimada:').style?.fontSize,
      20,
    );
    expect(
      _spanStartingWith(description.text, 'Descrição:').style?.fontSize,
      20,
    );
    expect(guidelinesTitle.style?.fontSize, 20);
    expect(guideline.style?.fontSize, 18);
    await tester.ensureVisible(find.text('Iniciar treino'));
    expect(find.text('Iniciar treino'), findsOneWidget);
    expect(find.text('Treino finalizado'), findsNothing);
    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();
    expect(find.text('Ver informações do treino'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('finish-training-button')));
    await tester.tap(find.byKey(const Key('finish-training-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('finish-training-dialog')), findsOneWidget);
  });

  // Registros concluídos permanecem consultivos e não exibem ação de início.
  testWidgets('renders the disabled finished state', (tester) async {
    await tester.pumpWidget(buildScreen(finished: true));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Treino finalizado'));
    expect(find.text('Treino finalizado'), findsOneWidget);
    expect(find.text('Iniciar treino'), findsNothing);
  });

  // A permissão falsa deve ocultar a ação sem esconder o conteúdo consultivo.
  testWidgets('read-only training does not expose an execution action', (
    tester,
  ) async {
    await tester.pumpWidget(buildScreen(finished: false, canStart: false));
    await tester.pumpAndSettle();

    expect(find.text('Trabalho de transições'), findsOneWidget);
    expect(
      find.byKey(const Key('training-execution-primary-action')),
      findsNothing,
    );
    expect(find.text('Iniciar treino'), findsNothing);
  // Percorre as três rotas para verificar o retorno do sucesso até os detalhes.
  testWidgets('refreshes to the finished state after submitting completion', (
    tester,
  ) async {
    final backend = _MutableExecutionBackend();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TrainingExecutionScreen(
          loader: backend,
          completionSubmitter: backend,
          reference: TrainingExecutionReference(
            recordId: 'registro-1',
            planId: 'plano-1',
            title: 'Trabalho de transições',
            date: DateTime(2026, 11, 21),
            durationMinutes: 45,
            status: TrainingAgendaStatus.planned,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Iniciar treino'));
    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('finish-training-button')));
    await tester.tap(find.byKey(const Key('finish-training-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sim'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('submit-training-completion')),
    );
    await tester.tap(find.byKey(const Key('submit-training-completion')));
    await tester.pumpAndSettle();

    expect(backend.fetchCount, 2);
    expect(backend.lastFetchedFinished, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Treino finalizado'), findsOneWidget);
    expect(find.text('Iniciar treino'), findsNothing);
    final action = tester.widget<InkWell>(
      find.byKey(const Key('training-execution-primary-action')),
    );
    expect(action.onTap, isNull);
  });
});
}

TextSpan _spanStartingWith(InlineSpan span, String prefix) {
  if (span is TextSpan) {
    if (span.text?.startsWith(prefix) ?? false) return span;
    for (final child in span.children ?? const <InlineSpan>[]) {
      try {
        return _spanStartingWith(child, prefix);
      } on StateError {
        // Continua procurando nos demais ramos da árvore de spans.
      }
    }
  }
  throw StateError('Span não encontrado: $prefix');
}

// Devolve conteúdo estável e deriva o estado finalizado da referência do teste.
class _FakeExecutionLoader implements TrainingExecutionLoader {
  const _FakeExecutionLoader({required this.finished});
  final bool finished;

  @override
  Future<TrainingExecutionData> fetchTraining(
    TrainingExecutionReference reference,
  ) async => TrainingExecutionData(
    recordId: reference.recordId,
    title: reference.title,
    durationMinutes: 45,
    description: 'Sessão focada em equilíbrio nas transições.',
    guidelines: const ['Encerrar com 5 minutos de passo.'],
    exercises: const [
      TrainingExecutionExercise(
        code: '12',
        name: 'Aquecimento ao passo',
        durationMinutes: 10,
        description: 'Caminhada em pista para aquecimento muscular.',
      ),
    ],
    isFinished: finished,
    canStart: reference.canStart,
  );
}

// Dependência obrigatória usada apenas quando o fluxo alcança a tela ativa.
class _FakeCompletionSubmitter implements TrainingCompletionSubmitter {
  const _FakeCompletionSubmitter();

  @override
  Future<TrainingCompletionResult> submit(
    TrainingCompletionInput input,
  ) async => const TrainingCompletionResult(status: 'REALIZADO');
}

// Simula a mesma fronteira usada para consultar e registrar uma execução.
class _MutableExecutionBackend
    implements TrainingExecutionLoader, TrainingCompletionSubmitter {
  int fetchCount = 0;

  // Mantém a resposta deliberadamente desatualizada para provar que o bloqueio
  // local protege a ação até a próxima resposta consistente do backend.
  bool? lastFetchedFinished;

  @override
  Future<TrainingExecutionData> fetchTraining(
    TrainingExecutionReference reference,
  ) async {
    fetchCount++;
    lastFetchedFinished = false;
    return TrainingExecutionData(
      recordId: reference.recordId,
      title: reference.title,
      durationMinutes: 45,
      description: 'Sessão focada em equilíbrio nas transições.',
      guidelines: const ['Encerrar com 5 minutos de passo.'],
      exercises: const [
        TrainingExecutionExercise(
          code: '12',
          name: 'Aquecimento ao passo',
          durationMinutes: 10,
          description: 'Caminhada em pista para aquecimento muscular.',
        ),
      ],
      isFinished: false,
    );
  }

  @override
  Future<TrainingCompletionResult> submit(TrainingCompletionInput input) async {
    return const TrainingCompletionResult(status: 'NAO_REALIZADO');
  }
}
