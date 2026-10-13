// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da SnackBar genérica para validar cor, ícone,
// mensagem e ação de fechar configuráveis.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';

void main() {
  // Valida o contrato configurável do componente compartilhado.
  testWidgets('shows a SnackBar with the provided configuration', (
    tester,
  ) async {
    // Preparação de uma configuração diferente do cenário de erro do login.
    const backgroundColor = Color(0xFF007A33);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => AppSnackBar.show(
                  context,
                  backgroundColor: backgroundColor,
                  icon: Icons.check_circle,
                  message: 'Operação concluída',
                ),
                child: const Text('Exibir mensagem'),
              );
            },
          ),
        ),
      ),
    );

    // Ação que solicita a exibição da SnackBar.
    await tester.tap(find.text('Exibir mensagem'));
    await tester.pumpAndSettle();

    // Verificação dos valores encaminhados ao componente Material.
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, backgroundColor);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Operação concluída'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
