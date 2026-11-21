// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da composição do login e do fechamento da rota após a
// autenticação.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/authentication/application/controllers/login_controller.dart';
import 'package:horse_life/features/authentication/application/states/login_session.dart';
import 'package:horse_life/features/authentication/data/repositories/login_repository.dart';
import 'package:horse_life/features/authentication/presentation/routes/login_flow_route.dart';
import 'package:horse_life/features/authentication/presentation/screens/login_screen.dart';

void main() {
  testWidgets('closes the login route after authentication', (tester) async {
    const session = LoginSession(
      uid: 'trainer-uid',
      name: 'Bruno Lima',
      role: AuthenticationRole.trainer,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.of(context).push<void>(
                LoginFlowRoute.build(
                  controller: LoginController(_FakeLoginRepository(session)),
                ),
              );
            },
            child: const Text('Abrir login'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir login'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'Senha@123');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Abrir login'), findsOneWidget);
  });
}

final class _FakeLoginRepository implements LoginRepository {
  const _FakeLoginRepository(this.session);

  final LoginSession session;

  @override
  Future<LoginSession> authenticate({
    required String email,
    required String password,
  }) async => session;
}
