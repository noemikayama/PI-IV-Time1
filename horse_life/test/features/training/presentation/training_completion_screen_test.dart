// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura do redirecionamento direto à agenda de treinos após o
// envio e do modal de confirmação ao acionar o botão de voltar.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão dos cenários de nota inválida e treino não realizado no
// formulário integrado ao registro da execução.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação e cobertura dos campos condicionais, da percepção
// numérica e do envio do formulário de registro da execução.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do resumo, preenchimento, validação e envio do formulário
// de conclusão do treinamento pelo atleta.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/presentation/screens/training_completion_screen.dart';

void main() {
  Route<dynamic>? generateAgendaRoute(RouteSettings settings) {
    if (settings.name == authenticatedHomeRouteName) {
      final destination = settings.arguments! as HomeNavigationDestination;
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => Scaffold(body: Text('Destino: ${destination.name}')),
      );
    }
    return null;
  }

  // Percorre resumo, campos obrigatórios e envio para validar o formulário e o
  // redirecionamento sem pilha para a agenda de treinos.
  testWidgets('renders summary, submits form, and redirects to trainings agenda', (
    tester,
  ) async {
    final submitter = _RecordingSubmitter();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: generateAgendaRoute,
        home: TrainingCompletionScreen(
          submitter: submitter,
          initialInput: _input,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Treinamento\nconcluído'), findsOneWidget);
    expect(find.textContaining('01:02:03'), findsOneWidget);
    expect(find.textContaining('Exercícios concluídos: 1'), findsOneWidget);
    expect(find.textContaining('Exercícios incompletos: 1'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Informe uma nota de 1 a 10'),
      '8',
    );
    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        'Ex.: Complicações quando está na mão esquerda',
      ),
      'Mão esquerda',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ex.: Cavalo mais agitado no início'),
      'Mais agitado no início',
    );
    await tester.ensureVisible(
      find.byKey(const Key('submit-training-completion')),
    );
    await tester.tap(find.byKey(const Key('submit-training-completion')));
    await tester.pumpAndSettle();

    expect(submitter.input?.performancePerception, 8);
    expect(submitter.input?.difficulty, 'Mão esquerda');
    expect(submitter.input?.notes, 'Mais agitado no início');
    expect(find.text('Destino: trainings'), findsOneWidget);
    expect(find.byType(TrainingCompletionScreen), findsNothing);
    expect(
      Navigator.of(tester.element(find.text('Destino: trainings'))).canPop(),
      isFalse,
    );
  });

  // Confirma que valores rejeitados pelo backend não chegam ao submitter.
  testWidgets('requires a performance score from 1 to 10', (tester) async {
    final submitter = _RecordingSubmitter();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: generateAgendaRoute,
        home: TrainingCompletionScreen(
          submitter: submitter,
          initialInput: _input,
        ),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Informe uma nota de 1 a 10'),
      '11',
    );
    await tester.ensureVisible(
      find.byKey(const Key('submit-training-completion')),
    );
    await tester.tap(find.byKey(const Key('submit-training-completion')));
    await tester.pump();

    expect(find.text('Informe uma nota inteira de 1 a 10.'), findsOneWidget);
    expect(submitter.input, isNull);
  });

  // Confirma que campos proibidos são ocultados quando nada foi realizado.
  testWidgets('omits performance fields for a training not performed', (
    tester,
  ) async {
    final submitter = _RecordingSubmitter();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        onGenerateRoute: generateAgendaRoute,
        home: TrainingCompletionScreen(
          submitter: submitter,
          initialInput: _notPerformedInput,
        ),
      ),
    );

    expect(find.text('Percepção de desempenho:'), findsNothing);
    expect(find.text('Dificuldades encontradas:'), findsNothing);
    await tester.ensureVisible(
      find.byKey(const Key('submit-training-completion')),
    );
    await tester.tap(find.byKey(const Key('submit-training-completion')));
    await tester.pumpAndSettle();

    expect(submitter.input?.performancePerception, isNull);
    expect(submitter.input?.difficulty, isEmpty);
    expect(find.text('Destino: trainings'), findsOneWidget);
    expect(find.byType(TrainingCompletionScreen), findsNothing);
  });

  // Voltar na submissão exige confirmação e mantém os campos se cancelado.
  testWidgets('requires confirmation before backing out of completion screen', (
    tester,
  ) async {
    final submitter = _RecordingSubmitter();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => TrainingCompletionScreen(
                    submitter: submitter,
                    initialInput: _input,
                  ),
                ),
              ),
              child: const Text('Origem'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Origem'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ex.: Cavalo mais agitado no início'),
      'Observação em andamento',
    );
    await tester.tap(find.byKey(const Key('training-completion-back-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('destructive-confirmation-dialog')),
      findsOneWidget,
    );
    expect(
      find.text('Tem certeza que deseja sair sem enviar?'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('destructive-dialog-cancel-button')));
    await tester.pumpAndSettle();

    expect(find.byType(TrainingCompletionScreen), findsOneWidget);
    expect(find.text('Observação em andamento'), findsOneWidget);

    await tester.tap(find.byKey(const Key('training-completion-back-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('destructive-dialog-confirm-button')));
    await tester.pumpAndSettle();

    expect(find.byType(TrainingCompletionScreen), findsNothing);
    expect(find.text('Origem'), findsOneWidget);
  });
}

const _input = TrainingCompletionInput(
  recordId: 'registro-1',
  elapsed: Duration(hours: 1, minutes: 2, seconds: 3),
  performancePerception: null,
  difficulty: '',
  notes: '',
  exercises: [
    TrainingCompletionExercise(code: '12', completed: true),
    TrainingCompletionExercise(code: '13', completed: false),
  ],
);

const _notPerformedInput = TrainingCompletionInput(
  recordId: 'registro-2',
  elapsed: Duration(minutes: 5),
  performancePerception: null,
  difficulty: '',
  notes: '',
  exercises: [TrainingCompletionExercise(code: '12', completed: false)],
);

// Armazena o último formulário para permitir asserções após a navegação fechar.
class _RecordingSubmitter implements TrainingCompletionSubmitter {
  TrainingCompletionInput? input;

  @override
  Future<TrainingCompletionResult> submit(TrainingCompletionInput input) async {
    this.input = input;
    return const TrainingCompletionResult(status: 'PARCIAL');
  }
}
