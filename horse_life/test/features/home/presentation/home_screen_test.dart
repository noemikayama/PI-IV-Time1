// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do cenário de falha no logout e alinhamento da
// mensagem segura exibida ao usuário.
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da home temporária, do logout e do feedback de falha.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/home/presentation/screens/home_screen.dart';

void main() {
  Widget buildApp(HomeScreen home) {
    return MaterialApp(theme: AppTheme.light, home: home);
  }

  testWidgets('shows only the sign-out action and blocks duplicate requests', (
    tester,
  ) async {
    final completion = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      buildApp(
        HomeScreen(
          signOut: () {
            calls++;
            return completion.future;
          },
        ),
      ),
    );

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sign-out-button')));
    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completion.complete();
    await tester.pump();
  });

  testWidgets('shows a safe message when sign-out fails', (tester) async {
    await tester.pumpWidget(
      buildApp(HomeScreen(signOut: () async => throw Exception('failure'))),
    );

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pump();

    expect(
      find.text('Não foi possível sair. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Sair'), findsOneWidget);
  });
}
