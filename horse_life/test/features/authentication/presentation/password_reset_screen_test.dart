// RESPONSÁVEL: Noemi Kayama - 25004140

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/application/controllers/password_reset_controller.dart';
import 'package:horse_life/features/authentication/data/repositories/password_reset_repository.dart';
import 'package:horse_life/features/authentication/presentation/screens/password_reset_screen.dart';

final class _FakePasswordResetRepository implements PasswordResetRepository {
  const _FakePasswordResetRepository(this.request);

  final Future<String> Function(String email) request;

  @override
  Future<String> requestPasswordReset({required String email}) =>
      request(email);
}

void main() {
  PasswordResetController buildController(
    Future<String> Function(String email) request,
  ) => PasswordResetController(_FakePasswordResetRepository(request));

  Future<void> openRecovery(
    WidgetTester tester,
    PasswordResetController controller,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open-password-reset'),
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PasswordResetScreen(controller: controller),
                ),
              ),
              child: const Text('Login de teste'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-password-reset')));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String email) async {
    await tester.enterText(find.byType(TextFormField), email);
    await tester.tap(find.byKey(const Key('request-password-reset')));
    await tester.pump();
  }

  testWidgets('shows content and validates required email', (tester) async {
    await openRecovery(tester, buildController((_) async => 'ok'));

    expect(find.text('Recuperação de senha'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Seguinte'), findsOneWidget);
    expect(find.bySemanticsLabel('Símbolo HorseLife'), findsOneWidget);

    await tester.tap(find.byKey(const Key('request-password-reset')));
    await tester.pump();
    expect(find.text('Informe seu e-mail.'), findsOneWidget);
  });

  testWidgets('rejects a malformed email without submitting', (tester) async {
    var requests = 0;
    await openRecovery(
      tester,
      buildController((_) async {
        requests++;
        return 'ok';
      }),
    );

    await submit(tester, 'email-invalido');

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('accepts a valid email with 254 characters', (tester) async {
    final email = '${List.filled(242, 'a').join()}@example.com';
    String? receivedEmail;
    await openRecovery(
      tester,
      buildController((email) async {
        receivedEmail = email;
        return 'ok';
      }),
    );

    await submit(tester, email);
    await tester.pumpAndSettle();

    expect(email.length, 254);
    expect(receivedEmail, email);
    expect(find.text('E-mail enviado'), findsOneWidget);
  });

  testWidgets('rejects an email with 255 characters', (tester) async {
    final email = '${List.filled(243, 'a').join()}@example.com';
    var requests = 0;
    await openRecovery(
      tester,
      buildController((_) async {
        requests++;
        return 'ok';
      }),
    );

    await submit(tester, email);

    expect(email.length, 255);
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('submits from the keyboard action', (tester) async {
    String? receivedEmail;
    await openRecovery(
      tester,
      buildController((email) async {
        receivedEmail = email;
        return 'ok';
      }),
    );

    await tester.enterText(find.byType(TextFormField), 'usuario@email.com');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(receivedEmail, 'usuario@email.com');
    expect(find.text('E-mail enviado'), findsOneWidget);
  });

  testWidgets('shows success and returns to login after confirmation', (
    tester,
  ) async {
    String? receivedEmail;
    await openRecovery(
      tester,
      buildController((email) async {
        receivedEmail = email;
        return 'Mensagem genérica';
      }),
    );

    await submit(tester, ' usuario@email.com ');
    await tester.pumpAndSettle();

    expect(receivedEmail, 'usuario@email.com');
    expect(find.text('E-mail enviado'), findsOneWidget);
    expect(
      find.textContaining('Verifique sua caixa de entrada'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('confirm-password-reset')));
    await tester.pumpAndSettle();

    expect(find.byType(PasswordResetScreen), findsNothing);
    expect(find.text('Login de teste'), findsOneWidget);
  });

  testWidgets('returns to login from the back button', (tester) async {
    await openRecovery(tester, buildController((_) async => 'ok'));

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.byType(PasswordResetScreen), findsNothing);
    expect(find.text('Login de teste'), findsOneWidget);
  });

  testWidgets('shows loading and ignores duplicate submissions', (
    tester,
  ) async {
    final response = Completer<String>();
    var requests = 0;
    await openRecovery(
      tester,
      buildController((_) {
        requests++;
        return response.future;
      }),
    );

    await tester.enterText(find.byType(TextFormField), 'usuario@email.com');
    await tester.tap(find.byKey(const Key('request-password-reset')));
    await tester.tap(find.byKey(const Key('request-password-reset')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(requests, 1);

    response.complete('ok');
    await tester.pumpAndSettle();
  });

  testWidgets('shows a typed invalid-email failure', (tester) async {
    await openRecovery(
      tester,
      buildController(
        (_) async => throw const PasswordResetFailure.invalidEmail(),
      ),
    );

    await submit(tester, 'usuario@email.com');

    expect(find.text('E-mail inválido.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a typed connection failure', (tester) async {
    await openRecovery(
      tester,
      buildController(
        (_) async => throw const PasswordResetFailure.connection(),
      ),
    );

    await submit(tester, 'usuario@email.com');

    expect(find.text('Erro de conexão com o servidor'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a connection failure after timeout', (tester) async {
    final response = Completer<String>();
    await openRecovery(tester, buildController((_) => response.future));

    await submit(tester, 'usuario@email.com');
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('Erro de conexão com o servidor'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a connection failure for an unexpected exception', (
    tester,
  ) async {
    await openRecovery(
      tester,
      buildController((_) async => throw StateError('unexpected')),
    );

    await submit(tester, 'usuario@email.com');

    expect(find.text('Erro de conexão com o servidor'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('unlocks submission and allows retry after failure', (
    tester,
  ) async {
    var requests = 0;
    await openRecovery(
      tester,
      buildController((_) async {
        requests++;
        if (requests == 1) throw const PasswordResetFailure.connection();
        return 'ok';
      }),
    );

    await submit(tester, 'usuario@email.com');
    expect(find.text('Erro de conexão com o servidor'), findsOneWidget);

    await tester.tap(find.byKey(const Key('request-password-reset')));
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('E-mail enviado'), findsOneWidget);
  });
}
