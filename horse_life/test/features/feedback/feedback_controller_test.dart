// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Testes unitários da navegação, das regras de validação e da
// montagem do feedback separados do comportamento visual das telas.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/feedback/application/controllers/feedback_registration_controller.dart';
import '../../support/features/feedback/data/repositories/mock_training_feedback_repository.dart';

void main() {
  test('mantém os valores ao avançar, voltar e editar a revisão', () {
    final controller = FeedbackRegistrationController();
    addTearDown(controller.dispose);

    expect(controller.step, 0);
    expect(controller.totalSteps, 4);
    expect(controller.previous(), isFalse);

    controller.textControllers[0].text = 'Treino bem executado.';
    controller.next();
    controller.textControllers[1].text = 'Ajustar equilíbrio.';
    controller.next();
    controller.textControllers[2].text = 'Repetir o exercício.';
    controller.next();

    expect(controller.isReview, isTrue);
    expect(controller.validateAll(), isNull);
    controller.edit(1);
    expect(controller.textControllers[1].text, 'Ajustar equilíbrio.');
    expect(controller.previous(), isTrue);
    expect(controller.textControllers[0].text, 'Treino bem executado.');
  });

  test('exige comentário, limita caracteres e aceita outros campos vazios', () {
    final controller = FeedbackRegistrationController();
    addTearDown(controller.dispose);

    expect(controller.validate(0, '  '), isNotNull);
    expect(controller.validate(1, '  '), isNull);
    expect(controller.validate(2, '  '), isNull);
    expect(controller.validate(0, List.filled(1001, 'x').join()), isNotNull);
    expect(controller.validate(0, List.filled(1000, 'x').join()), isNull);
    expect(controller.validateAll(), isNotNull);
  });

  test('converte campos com linhas em listas para o contrato do feedback', () {
    final controller = FeedbackRegistrationController();
    addTearDown(controller.dispose);

    controller.textControllers[0].text = '  Bom desempenho  ';
    controller.textControllers[1].text = '  Primeira  \n\n Segunda  ';
    controller.textControllers[2].text = '  Revisar postura  ';

    final feedback = controller.buildFeedback(createdAt: DateTime(2026, 11, 20));
    expect(feedback.comment, 'Bom desempenho');
    expect(feedback.difficulties, ['Primeira', 'Segunda']);
    expect(feedback.guidelines, ['Revisar postura']);
  });

  test('mock impede duplicidade e cadastro em registro inexistente', () {
    final repository = MockTrainingFeedbackRepository.instance;
    repository.reset();
    addTearDown(repository.reset);
    final controller = FeedbackRegistrationController();
    addTearDown(controller.dispose);
    controller.textControllers[0].text = 'Boa execução';
    final feedback = controller.buildFeedback();

    expect(
      () => repository.registerFeedback(recordId: 'desconhecido', feedback: feedback),
      throwsStateError,
    );
    expect(
      () => repository.registerFeedback(
        recordId: 'feedback-demo-registrado',
        feedback: feedback,
      ),
      throwsStateError,
    );
    repository.registerFeedback(recordId: 'feedback-demo-pendente', feedback: feedback);
    expect(repository.findById('feedback-demo-pendente')?.feedback?.comment, 'Boa execução');
  });
}
