// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Ampliação da cobertura da navegação de revisão editável e
// da consulta de feedback disponível pelo responsável.
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Testes dos dados simulados, do aviso sem feedback e do fluxo
// completo de cadastro e leitura pelo profissional.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/feedback/data/repositories/mock_training_feedback_repository.dart';
import 'package:horse_life/features/feedback/presentation/screens/training_execution_record_screen.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';

void main() {
  final repository = MockTrainingFeedbackRepository.instance;

  setUp(repository.reset);

  test('mantém casos com feedback ausente e presente', () {
    expect(repository.findById('feedback-demo-pendente')?.feedback, isNull);
    expect(repository.findById('feedback-demo-registrado')?.feedback, isNotNull);
  });

  testWidgets('responsável recebe modal quando ainda não há feedback', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: TrainingExecutionRecordScreen(
        recordId: 'feedback-demo-pendente',
        audience: TrainingAgendaAudience.guardian,
        repository: repository,
      ),
    ));

    await tester.ensureVisible(find.byKey(const Key('access-feedback-button')));
    await tester.tap(find.byKey(const Key('access-feedback-button')));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum feedback registrado'), findsOneWidget);
    await tester.tap(find.byKey(const Key('feedback-empty-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum feedback registrado'), findsNothing);
  });

  testWidgets('profissional registra feedback e pode consultá-lo', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: TrainingExecutionRecordScreen(
        recordId: 'feedback-demo-pendente',
        audience: TrainingAgendaAudience.trainer,
        repository: repository,
      ),
    ));

    await tester.ensureVisible(find.text('Escrever feedback'));
    await tester.tap(find.text('Escrever feedback'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('feedback-input-1')),
      'Boa execução dos exercícios.',
    );
    await tester.ensureVisible(find.byKey(const Key('feedback-continue-1')));
    await tester.tap(find.byKey(const Key('feedback-continue-1')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('feedback-input-2')),
      'Atenção ao lado esquerdo.',
    );
    await tester.ensureVisible(find.byKey(const Key('feedback-continue-2')));
    await tester.tap(find.byKey(const Key('feedback-continue-2')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('feedback-input-3')),
      'Repetir as transições.',
    );
    await tester.ensureVisible(find.byKey(const Key('feedback-continue-3')));
    await tester.tap(find.byKey(const Key('feedback-continue-3')));
    await tester.pumpAndSettle();

    expect(find.text('Revise os dados'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('feedback-continue-4')));
    await tester.tap(find.byKey(const Key('feedback-continue-4')));
    await tester.pumpAndSettle();

    expect(repository.findById('feedback-demo-pendente')?.feedback?.comment,
        'Boa execução dos exercícios.');
    await tester.ensureVisible(find.text('Visualizar feedback'));
    await tester.tap(find.text('Visualizar feedback'));
    await tester.pumpAndSettle();
    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('Boa execução dos exercícios.'), findsOneWidget);
  });

  testWidgets('responsável acessa feedback já registrado', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: TrainingExecutionRecordScreen(
        recordId: 'feedback-demo-registrado',
        audience: TrainingAgendaAudience.guardian,
        repository: repository,
      ),
    ));

    await tester.ensureVisible(find.text('Visualizar feedback'));
    await tester.tap(find.text('Visualizar feedback'));
    await tester.pumpAndSettle();

    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('Comentários sobre a execução'), findsOneWidget);
    expect(find.text('Dificuldades identificadas'), findsOneWidget);
  });

  testWidgets('etapa de revisão permite editar sem perder respostas', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: TrainingExecutionRecordScreen(
        recordId: 'feedback-demo-pendente',
        audience: TrainingAgendaAudience.trainer,
        repository: repository,
      ),
    ));

    await tester.ensureVisible(find.text('Escrever feedback'));
    await tester.tap(find.text('Escrever feedback'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('feedback-input-1')),
      'Comentário inicial',
    );
    for (var step = 1; step <= 3; step++) {
      await tester.ensureVisible(find.byKey(Key('feedback-continue-$step')));
      await tester.tap(find.byKey(Key('feedback-continue-$step')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Revise os dados'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('Editar Comentários sobre a execução'));
    await tester.tap(find.byTooltip('Editar Comentários sobre a execução'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feedback-input-1')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('feedback-input-1')), 'Comentário corrigido');
    for (var step = 1; step <= 3; step++) {
      await tester.ensureVisible(find.byKey(Key('feedback-continue-$step')));
      await tester.tap(find.byKey(Key('feedback-continue-$step')));
      await tester.pumpAndSettle();
    }

    await tester.ensureVisible(find.byKey(const Key('feedback-continue-4')));
    await tester.tap(find.byKey(const Key('feedback-continue-4')));
    await tester.pumpAndSettle();
    expect(repository.findById('feedback-demo-pendente')?.feedback?.comment,
        'Comentário corrigido');
  });

}
