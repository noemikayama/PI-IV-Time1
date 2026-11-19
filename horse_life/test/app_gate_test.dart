// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da restauração da sessão, abertura da home e retorno ao
// conteúdo público depois do logout.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da splash de quatro segundos, do carregamento
// do Firebase e da recuperação após falha de inicialização.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/app.dart';
import 'package:horse_life/features/authentication/application/states/login_session.dart';
import 'package:horse_life/features/authentication/data/repositories/authentication_session_repository.dart';
import 'package:horse_life/features/home/presentation/screens/home_screen.dart';

void main() {
  // Cenário 1: inicialização imediata ainda respeita a duração visual mínima.
  // Valida a duração mínima quando o Firebase responde imediatamente.
  testWidgets(
    'keeps the splash visible when Firebase initializes immediately',
    (tester) async {
      // Preparação da aplicação com uma inicialização bem-sucedida.
      await tester.pumpWidget(
        HorseLifeApp(initializeApp: () async {}, home: const Text('Início')),
      );

      // Mantém o relógio imediatamente antes do limite mínimo.
      await tester.pump(const Duration(milliseconds: 3999));

      // Verificação do estado imediatamente anterior ao limite.
      expect(find.bySemanticsLabel('HorseLife'), findsOneWidget);
      expect(find.bySemanticsLabel('Carregando HorseLife'), findsOneWidget);
      expect(find.text('Início'), findsNothing);

      // Completa os quatro segundos e libera a tela principal.
      await tester.pump(const Duration(milliseconds: 1));

      // Verificação da liberação do conteúdo principal.
      expect(find.text('Início'), findsOneWidget);
      expect(find.bySemanticsLabel('Carregando HorseLife'), findsNothing);
    },
  );

  // Cenário 2: uma dependência pendente mantém a splash em exibição.
  testWidgets('shows the splash while Firebase initializes', (tester) async {
    // Controla manualmente o instante em que a inicialização termina.
    final initialization = Completer<void>();

    // Preparação com um Future controlado pelo teste.
    await tester.pumpWidget(
      HorseLifeApp(
        initializeApp: () => initialization.future,
        home: const Text('Início'),
      ),
    );

    // Verificação do estado de carregamento.
    expect(find.bySemanticsLabel('HorseLife'), findsOneWidget);
    expect(find.bySemanticsLabel('Carregando HorseLife'), findsOneWidget);
    expect(find.text('Início'), findsNothing);

    // Conclui o Firebase e avança o tempo mínimo antes de validar a
    // transição.
    initialization.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    // Verificação da transição após as duas condições serem concluídas.
    expect(find.text('Início'), findsOneWidget);
    expect(find.bySemanticsLabel('Carregando HorseLife'), findsNothing);
  });

  // Cenário 3: uma falha oferece recuperação por nova tentativa.
  testWidgets('offers a retry when initialization fails', (tester) async {
    var attempts = 0;

    // Simula falha na primeira tentativa e sucesso na segunda.
    Future<void> initialize() async {
      attempts++;
      if (attempts == 1) {
        throw Exception('Firebase unavailable');
      }
    }

    // Execução da primeira tentativa, configurada para falhar.
    await tester.pumpWidget(
      HorseLifeApp(initializeApp: initialize, home: const Text('Início')),
    );
    await tester.pump(const Duration(seconds: 4));

    // Verificação da apresentação do estado de erro.
    expect(
      find.text('Não foi possível conectar ao HorseLife.'),
      findsOneWidget,
    );
    expect(find.text('Tentar novamente'), findsOneWidget);

    // Aciona a recuperação e aguarda o novo ciclo de inicialização.
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));

    // Verificação da recuperação e do número de tentativas realizadas.
    expect(attempts, 2);
    expect(find.text('Início'), findsOneWidget);
  });

  testWidgets('restores an authenticated session and opens the home', (
    tester,
  ) async {
    final repository = _FakeSessionRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      HorseLifeApp(
        initializeApp: () async {},
        home: const Text('Boas-vindas'),
        sessionRepository: repository,
      ),
    );
    await tester.pump(const Duration(seconds: 4));

    repository.emit(
      const LoginSession(
        uid: 'guardian-uid',
        name: 'Ana Silva',
        role: AuthenticationRole.guardian,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
    expect(find.text('Boas-vindas'), findsNothing);
  });

  testWidgets('returns to the public content after signing out', (
    tester,
  ) async {
    final repository = _FakeSessionRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      HorseLifeApp(
        initializeApp: () async {},
        home: const Text('Boas-vindas'),
        sessionRepository: repository,
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    repository.emit(
      const LoginSession(
        uid: 'trainer-uid',
        name: 'Bruno Lima',
        role: AuthenticationRole.trainer,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
    expect(find.text('Boas-vindas'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });
}

final class _FakeSessionRepository implements AuthenticationSessionRepository {
  final _controller = StreamController<LoginSession?>();
  var signOutCalls = 0;

  void emit(LoginSession? session) => _controller.add(session);

  void dispose() => _controller.close();

  @override
  Stream<LoginSession?> watchSession() => _controller.stream;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    emit(null);
  }
}
