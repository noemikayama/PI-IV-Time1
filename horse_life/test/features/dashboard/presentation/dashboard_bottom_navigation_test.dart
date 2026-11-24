// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da regressão que exige redirecionamento direto da barra
// inferior do dashboard, sem retorno pela pilha de navegação.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/dashboard/data/models/dashboard_response.dart';
import 'package:horse_life/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:horse_life/features/dashboard/presentation/screens/guardian/guardian_dashboard_screen.dart';

void main() {
  const destinations = {
    'Home': HomeNavigationDestination.home,
    'Treinos': HomeNavigationDestination.trainings,
    'Cavalos': HomeNavigationDestination.horses,
    'Perfil': HomeNavigationDestination.profile,
  };

  for (final entry in destinations.entries) {
    testWidgets('redirects ${entry.key} without popping the dashboard', (
      tester,
    ) async {
      final observer = _NavigationObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          onGenerateRoute: (settings) {
            if (settings.name == authenticatedHomeRouteName) {
              final destination =
                  settings.arguments! as HomeNavigationDestination;
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) =>
                    Scaffold(body: Text('Destino: ${destination.name}')),
              );
            }
            return null;
          },
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => GuardianDashboardScreen(
                      onLogout: () async {},
                      repository: _EmptyDashboardRepository(),
                    ),
                  ),
                ),
                child: const Text('Abrir dashboard'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir dashboard'));
      await tester.pumpAndSettle();
      observer.popCount = 0;

      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();

      expect(find.text('Destino: ${entry.value.name}'), findsOneWidget);
      expect(observer.popCount, 0);
    });
  }

  testWidgets('keeps dashboard selected without popping its route', (
    tester,
  ) async {
    final observer = _NavigationObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: GuardianDashboardScreen(
          onLogout: () async {},
          repository: _EmptyDashboardRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    observer.popCount = 0;

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    expect(find.byType(GuardianDashboardScreen), findsOneWidget);
    expect(observer.popCount, 0);
  });
}

class _EmptyDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardResponse> getDashboard({
    required String period,
    String? horseId,
    required bool professional,
  }) async {
    return DashboardResponse(const {
      'tipoConta': 'RESPONSAVEL',
      'possuiDados': false,
    });
  }
}

class _NavigationObserver extends NavigatorObserver {
  var popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}
