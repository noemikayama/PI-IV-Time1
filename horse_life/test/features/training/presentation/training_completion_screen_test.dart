// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do cenário de preenchimento e do dublê que captura o
// formulário submetido pela tela de conclusão.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do resumo, preenchimento, validação e envio do formulário
// de conclusão do treinamento pelo atleta.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/presentation/screens/training_completion_screen.dart';

void main() {
  // Percorre resumo, campos obrigatórios e envio para validar o formulário como
  // o atleta o utiliza, sem depender de Firebase.
  testWidgets('renders summary and submits the athlete form', (tester) async {
    final submitter = _RecordingSubmitter();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
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
      find.widgetWithText(TextFormField, 'Ex.: Executado com facilidade'),
      'Boa evolução',
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

    expect(submitter.input?.performancePerception, 'Boa evolução');
    expect(submitter.input?.difficulty, 'Mão esquerda');
    expect(submitter.input?.notes, 'Mais agitado no início');
  });
}

const _input = TrainingCompletionInput(
  recordId: 'registro-1',
  elapsed: Duration(hours: 1, minutes: 2, seconds: 3),
  performancePerception: '',
  difficulty: '',
  notes: '',
  exercises: [
    TrainingCompletionExercise(code: '12', completed: true),
    TrainingCompletionExercise(code: '13', completed: false),
  ],
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
