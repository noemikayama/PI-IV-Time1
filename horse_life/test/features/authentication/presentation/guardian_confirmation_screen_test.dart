// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Uso do estado específico de responsável na revisão do cadastro.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da confirmação e submissão do cadastro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/application/controllers/registration_controller.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/data/repositories/registration_repository.dart';
import 'package:horse_life/features/authentication/presentation/screens/guardian_confirmation_screen.dart';

void main() {
  // Draft de revisão sem armazenamento da senha.
  const registration = GuardianRegistrationDraft(
    firstName: 'Ana',
    lastName: 'Silva',
    email: 'ana@email.com',
  );

  // Montagem isolada com tema e Navigator reais.
  Widget buildApp(Widget home) {
    return MaterialApp(theme: AppTheme.light, home: home);
  }

  // Conteúdo, mascaramento da senha e progresso final.
  testWidgets('reviews all data with only the fourth segment active', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const GuardianConfirmationScreen(
          registration: registration,
          password: 'Senha@123',
        ),
      ),
    );

    expect(find.text('Revise seus dados'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Silva'), findsOneWidget);
    expect(find.text('ana@email.com'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 4 de 4'), findsOneWidget);

    var passwordInput = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('review-password')),
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordInput.obscureText, isTrue);

    for (var step = 1; step <= 4; step++) {
      final segment = tester.widget<Container>(
        find.byKey(Key('registration-progress-segment-$step')),
      );
      final decoration = segment.decoration! as BoxDecoration;
      expect(
        decoration.color,
        step == 4 ? AppColors.seaGreen : AppColors.alabasterGray,
      );
    }

    final showPasswordButton = find.byTooltip('Mostrar senha');
    await tester.ensureVisible(showPasswordButton);
    await tester.tap(showPasswordButton);
    await tester.pump();
    passwordInput = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('review-password')),
        matching: find.byType(EditableText),
      ),
    );
    expect(passwordInput.obscureText, isFalse);
  });

  // Passagem separada de dados e senha pelo controller.
  testWidgets('submits data and transient password through the controller', (
    tester,
  ) async {
    final repository = _FakeRegistrationRepository();
    var wasCreated = false;

    await tester.pumpWidget(
      buildApp(
        GuardianConfirmationScreen(
          registration: registration,
          password: 'Senha@123',
          registrationController: RegistrationController(repository),
          onCreated: () => wasCreated = true,
        ),
      ),
    );

    final createButton = find.byKey(const Key('create-registration-account'));
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(repository.receivedRegistration?.firstName, 'Ana');
    expect(repository.receivedRegistration?.lastName, 'Silva');
    expect(repository.receivedRegistration?.email, 'ana@email.com');
    expect(repository.receivedPassword, 'Senha@123');
    expect(wasCreated, isTrue);
  });

  // Edição inline e uso dos valores atualizados na submissão.
  testWidgets('edits information inline and submits the updated values', (
    tester,
  ) async {
    final repository = _FakeRegistrationRepository();

    await tester.pumpWidget(
      buildApp(
        GuardianConfirmationScreen(
          registration: registration,
          password: 'Senha@123',
          registrationController: RegistrationController(repository),
        ),
      ),
    );

    final editFirstName = find.byTooltip('Editar Primeiro nome');
    await tester.ensureVisible(editFirstName);
    await tester.tap(editFirstName);
    await tester.pump();

    expect(find.byType(GuardianConfirmationScreen), findsOneWidget);
    expect(find.byTooltip('Concluir edição de Primeiro nome'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('review-first-name')),
      'Beatriz',
    );
    await tester.tap(find.byTooltip('Concluir edição de Primeiro nome'));
    await tester.pump();

    final createButton = find.byKey(const Key('create-registration-account'));
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(repository.receivedRegistration?.firstName, 'Beatriz');
    expect(repository.receivedRegistration?.lastName, 'Silva');
    expect(repository.receivedRegistration?.email, 'ana@email.com');
  });

  // Comportamento explícito enquanto a Firebase Function não está integrada.
  testWidgets('shows a connection error before the backend is connected', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const GuardianConfirmationScreen(
          registration: registration,
          password: 'Senha@123',
        ),
      ),
    );

    final createButton = find.byKey(const Key('create-registration-account'));
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pump();

    expect(find.text('Erro de conexão com o servidor'), findsOneWidget);
  });
}

class _FakeRegistrationRepository implements RegistrationRepository {
  // Capturas usadas para verificar o contrato sem acessar serviços externos.
  RegistrationDraft? receivedRegistration;
  String? receivedPassword;

  @override
  Future<void> createAccount({
    required RegistrationDraft registration,
    required String password,
  }) async {
    receivedRegistration = registration;
    receivedPassword = password;
  }
}
