// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da etapa de senha do cadastro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/presentation/screens/guardian_confirmation_screen.dart';
import 'package:horse_life/features/authentication/presentation/screens/registration_password_screen.dart';

void main() {
  // Draft não sensível usado em todos os cenários da senha.
  const initialRegistration = RegistrationDraft(
    firstName: 'Ana',
    lastName: 'Silva',
    email: 'ana@email.com',
  );

  // Montagem isolada com o tema institucional.
  Widget buildApp(Widget home) {
    return MaterialApp(theme: AppTheme.light, home: home);
  }

  // Estrutura da terceira etapa e estado inicial dos requisitos.
  testWidgets('shows the password step with the third segment active', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const RegistrationPasswordScreen(registration: initialRegistration),
      ),
    );

    expect(find.text('Crie uma senha'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Confirmação da senha'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 3 de 4'), findsOneWidget);
    expect(
      find.byKey(const Key('password-requirement-unmet-de 8 a 30 caracteres')),
      findsOneWidget,
    );
  });

  // Reação imediata dos cinco critérios durante a digitação.
  testWidgets('updates every requirement while the password is typed', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const RegistrationPasswordScreen(registration: initialRegistration),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Senha@123');
    await tester.pump();

    expect(
      find.byKey(const Key('password-requirement-met-de 8 a 30 caracteres')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('password-requirement-met-1 caractere minúsculo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('password-requirement-met-1 caractere maiúsculo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('password-requirement-met-1 número')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('password-requirement-met-1 caractere especial')),
      findsOneWidget,
    );
  });

  // Bloqueio da divergência e entrega separada da senha válida.
  testWidgets('blocks mismatched confirmation and passes an exact match', (
    tester,
  ) async {
    RegistrationDraft? receivedRegistration;
    String? receivedPassword;

    await tester.pumpWidget(
      buildApp(
        RegistrationPasswordScreen(
          registration: initialRegistration,
          onContinue: (registration, password) {
            receivedRegistration = registration;
            receivedPassword = password;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Senha@123');
    await tester.enterText(find.byType(TextFormField).last, 'Senha@124');

    final continueButton = find.byKey(
      const Key('continue-registration-password'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.text('As senhas não coincidem.'), findsOneWidget);
    expect(receivedRegistration, isNull);

    await tester.enterText(find.byType(TextFormField).last, 'Senha@123');
    await tester.tap(continueButton);

    expect(receivedRegistration?.firstName, 'Ana');
    expect(receivedRegistration?.lastName, 'Silva');
    expect(receivedRegistration?.email, 'ana@email.com');
    expect(receivedPassword, 'Senha@123');
  });

  // Navegação para revisão e retorno explícito à própria etapa de senha.
  testWidgets('opens confirmation with data and a transient password', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const RegistrationPasswordScreen(registration: initialRegistration),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Senha@123');
    await tester.enterText(find.byType(TextFormField).last, 'Senha@123');
    final continueButton = find.byKey(
      const Key('continue-registration-password'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(GuardianConfirmationScreen), findsOneWidget);
    expect(find.text('Revise seus dados'), findsOneWidget);

    final editPassword = find.byTooltip('Editar Senha');
    await tester.ensureVisible(editPassword);
    await tester.tap(editPassword);
    await tester.pumpAndSettle();

    expect(find.byType(GuardianConfirmationScreen), findsNothing);
    expect(find.byType(RegistrationPasswordScreen), findsOneWidget);
    expect(find.text('Crie uma senha'), findsOneWidget);
  });
}
