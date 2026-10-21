// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da composição padrão e da injeção de teste na
// rota do fluxo de cadastro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/authentication/application/controllers/registration_controller.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/data/repositories/registration_repository.dart';
import 'package:horse_life/features/authentication/presentation/routes/registration_flow_route.dart';
import 'package:horse_life/features/authentication/presentation/screens/profile_selection_screen.dart';

void main() {
  testWidgets('builds the registration flow with its default controller', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());

    await tester.tap(find.text('Abrir cadastro'));
    await tester.pumpAndSettle();

    final screen = tester.widget<ProfileSelectionScreen>(
      find.byType(ProfileSelectionScreen),
    );
    expect(screen.registrationController, isNotNull);
  });

  testWidgets('uses an injected controller when provided', (tester) async {
    final controller = RegistrationController(_FakeRegistrationRepository());

    await tester.pumpWidget(_buildApp(registrationController: controller));

    await tester.tap(find.text('Abrir cadastro'));
    await tester.pumpAndSettle();

    final screen = tester.widget<ProfileSelectionScreen>(
      find.byType(ProfileSelectionScreen),
    );
    expect(screen.registrationController, same(controller));
  });
}

Widget _buildApp({RegistrationController? registrationController}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.push(
          context,
          RegistrationFlowRoute.build(
            registrationController: registrationController,
          ),
        ),
        child: const Text('Abrir cadastro'),
      ),
    ),
  );
}

final class _FakeRegistrationRepository implements RegistrationRepository {
  @override
  Future<void> createAccount({
    required RegistrationDraft registration,
    required String password,
  }) async {}
}
