// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos cenários de interação, controle do cronômetro,
// diálogos e transição para o formulário final.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da execução ativa, incluindo exercícios, informações,
// cronômetro, confirmação de encerramento e abertura do formulário final.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';
import 'package:horse_life/features/training/data/models/training_execution_data.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/presentation/screens/active_training_screen.dart';

void main() {
  // A ação deve alternar o mesmo exercício sem duplicar índices no estado.
  testWidgets('toggles an exercise between finish and restart states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ActiveTrainingScreen(
          training: _training,
          completionSubmitter: _submitter,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Exercícios realizados: 0/1'), findsOneWidget);
    expect(find.text('Finalizar exercício'), findsOneWidget);

    await tester.ensureVisible(find.text('Finalizar exercício'));
    await tester.tap(find.byKey(const Key('toggle-exercise-0')));
    await tester.pump();

    expect(find.text('Exercícios realizados: 1/1'), findsOneWidget);
    expect(find.text('Reiniciar exercício'), findsOneWidget);

    await tester.tap(find.byKey(const Key('toggle-exercise-0')));
    await tester.pump();
    expect(find.text('Exercícios realizados: 0/1'), findsOneWidget);
    expect(find.text('Finalizar exercício'), findsOneWidget);
  });

  // Confirma a composição de navegação que entrega o treino à tela ativa.
  testWidgets('opens the execution screen from the start button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const ActiveTrainingScreen(
                  training: _training,
                  completionSubmitter: _submitter,
                ),
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Ver informações do treino'), findsOneWidget);
    expect(find.byKey(const Key('finish-training-button')), findsOneWidget);
  });

  // O modal consultivo não deve substituir nem encerrar a rota em execução.
  testWidgets('green information action opens and closes the centered dialog', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ActiveTrainingScreen(
          training: _training,
          completionSubmitter: _submitter,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Ver informações do treino'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('training-information-dialog')),
      findsOneWidget,
    );
    expect(find.text('Informações'), findsOneWidget);
    expect(find.textContaining('45 minutos'), findsOneWidget);
    expect(find.text('Sessão focada em equilíbrio.'), findsOneWidget);
    expect(find.text('Encerrar com cinco minutos de passo.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-training-information')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('training-information-dialog')), findsNothing);
  });

  // Cancelar o encerramento preserva a sessão e retoma o tempo decorrido.
  testWidgets('finish action pauses timer and cancel resumes it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const ActiveTrainingScreen(
          training: _training,
          completionSubmitter: _submitter,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.ensureVisible(find.byKey(const Key('finish-training-button')));
    await tester.tap(find.byKey(const Key('finish-training-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('finish-training-dialog')), findsOneWidget);
    expect(
      find.text('Tem certeza que deseja\nfinalizar o treino?'),
      findsOneWidget,
    );
    expect(
      find.textContaining('um ou mais exercícios não finalizados'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('training-timer-paused')),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(
      find.byKey(const ValueKey<String>('training-timer-paused')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('cancel-finish-training')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('training-timer-running')),
      findsOneWidget,
    );
  });

  // Confirmar cria o snapshot dos exercícios e substitui a rota pelo formulário.
  testWidgets('confirming finish opens the completion form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const ActiveTrainingScreen(
                  training: _training,
                  completionSubmitter: _submitter,
                ),
              ),
            ),
            child: const Text('Abrir execução'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir execução'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('finish-training-button')));
    await tester.tap(find.byKey(const Key('finish-training-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-finish-training')));
    await tester.pumpAndSettle();

    expect(find.byType(ActiveTrainingScreen), findsNothing);
    expect(find.text('Treinamento\nconcluído'), findsOneWidget);
    expect(find.text('Submeter registro'), findsOneWidget);
  });
}

const _submitter = _FakeCompletionSubmitter();

// Dublê sem efeitos externos; estes cenários terminam antes do envio do formulário.
class _FakeCompletionSubmitter implements TrainingCompletionSubmitter {
  const _FakeCompletionSubmitter();

  @override
  Future<TrainingCompletionResult> submit(
    TrainingCompletionInput input,
  ) async => const TrainingCompletionResult(status: 'PARCIAL');
}

const _training = TrainingExecutionData(
  recordId: 'registro-1',
  title: 'Trabalho de transições',
  durationMinutes: 45,
  description: 'Sessão focada em equilíbrio.',
  guidelines: ['Encerrar com cinco minutos de passo.'],
  exercises: [
    TrainingExecutionExercise(
      code: '12',
      name: 'Aquecimento ao passo',
      durationMinutes: 10,
      description: 'Caminhada em pista.',
      guidelines: ['Manter contato leve com as rédeas.'],
      materials: [
        TrainingExerciseMaterial(description: 'Cavalete', quantity: 3),
      ],
    ),
  ],
  isFinished: false,
);
