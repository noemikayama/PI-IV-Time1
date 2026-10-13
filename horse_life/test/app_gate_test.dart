// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Atualização dos testes para validar a splash durante quatro
// segundos.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes de duração da splash, carregamento do
// Firebase e recuperação após falha de inicialização.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/app.dart';

void main() {
  // Valida a duração mínima quando o Firebase responde imediatamente.
  testWidgets(
    'keeps the splash visible when Firebase initializes immediately',
    (tester) async {
      await tester.pumpWidget(
        HorseLifeApp(initializeApp: () async {}, home: const Text('Início')),
      );

      // Mantém o relógio imediatamente antes do limite mínimo.
      await tester.pump(const Duration(milliseconds: 3999));

      expect(find.bySemanticsLabel('HorseLife'), findsOneWidget);
      expect(find.bySemanticsLabel('Carregando HorseLife'), findsOneWidget);
      expect(find.text('Início'), findsNothing);

      // Completa os quatro segundos e libera a tela principal.
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.text('Início'), findsOneWidget);
      expect(find.bySemanticsLabel('Carregando HorseLife'), findsNothing);
    },
  );

  // Valida que uma inicialização pendente mantém a splash em exibição.
  testWidgets('shows the splash while Firebase initializes', (tester) async {
    // Controla manualmente o instante em que a inicialização termina.
    final initialization = Completer<void>();

    await tester.pumpWidget(
      HorseLifeApp(
        initializeApp: () => initialization.future,
        home: const Text('Início'),
      ),
    );

    expect(find.bySemanticsLabel('HorseLife'), findsOneWidget);
    expect(find.bySemanticsLabel('Carregando HorseLife'), findsOneWidget);
    expect(find.text('Início'), findsNothing);

    // Conclui o Firebase e avança o tempo mínimo antes de validar a
    // transição.
    initialization.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(find.text('Início'), findsOneWidget);
    expect(find.bySemanticsLabel('Carregando HorseLife'), findsNothing);
  });

  // Valida a mensagem de falha e a recuperação por nova tentativa.
  testWidgets('offers a retry when initialization fails', (tester) async {
    var attempts = 0;

    // Simula falha na primeira tentativa e sucesso na segunda.
    Future<void> initialize() async {
      attempts++;
      if (attempts == 1) {
        throw Exception('Firebase unavailable');
      }
    }

    await tester.pumpWidget(
      HorseLifeApp(initializeApp: initialize, home: const Text('Início')),
    );
    await tester.pump(const Duration(seconds: 4));

    expect(
      find.text('Não foi possível conectar ao HorseLife.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);

    // Aciona a recuperação e aguarda o novo ciclo de inicialização.
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    expect(attempts, 2);
    expect(find.text('Início'), findsOneWidget);
  });
}
