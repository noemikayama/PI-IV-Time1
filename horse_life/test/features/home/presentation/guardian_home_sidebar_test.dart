// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do recarregamento síncrono da Home ao retornar de uma
// lista de cavalos injetada, sem acesso aos serviços externos.
//
// Data: 18/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Adequação do teste à rota modular HorseRelationshipScreen e
// injeção de repositório exclusivo do teste para evitar acesso ao Firebase.
//
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura do link "Cadastrar cavalo" na barra lateral do responsável.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/guardian_sidebar.dart';
import 'package:horse_life/features/home/application/controllers/home_loader.dart';
import 'package:horse_life/features/home/data/models/guardian_home_data.dart';
import 'package:horse_life/features/home/presentation/screens/guardian/guardian_home_screen.dart';
import 'package:horse_life/features/horses/presentation/screens/horse_relationship_screen.dart';
import 'package:horse_life/features/horses/presentation/routes/horse_registration_flow_route.dart';
import 'package:horse_life/features/horses/data/repositories/mock_horse_registration_repository.dart';

void main() {
  // Reproduz a navegação completa e conta as consultas para validar a recarga.
  testWidgets('refreshes home synchronously after returning from horse list', (
    tester,
  ) async {
    final loader = _GuardianHomeLoader();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GuardianHomeScreen(
          loader: loader,
          onLogout: () async {},
          horseListBuilder: (_) => const Scaffold(
            body: Center(child: Text('Lista de cavalos de teste')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cavalos'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Lista de cavalos de teste'))).pop();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(loader.fetchCount, 2);
  });

  testWidgets(
    'opens horse registration flow when tapping Cadastrar cavalo in GuardianSidebar',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: AppTheme.light,
          home: GuardianHomeScreen(
            loader: _GuardianHomeLoader(),
            onLogout: () async {},
            onRegisterHorse: () {
              navigatorKey.currentState!.push(
                HorseRegistrationFlowRoute.build(
                  repository: const MockHorseRegistrationRepository(),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Abrir menu'));
      await tester.pumpAndSettle();

      expect(find.byType(GuardianSidebar), findsOneWidget);
      final registerHorseTile = find.byKey(
        const Key('guardian-sidebar-register-horse'),
      );
      expect(registerHorseTile, findsOneWidget);
      expect(find.text('Cadastrar cavalo'), findsOneWidget);

      await tester.tap(registerHorseTile);
      await tester.pumpAndSettle();

      expect(find.byType(HorseRelationshipScreen), findsOneWidget);
      expect(find.text('Relação com o cavalo'), findsOneWidget);
    },
  );
}

// Carregador determinístico que registra quantas vezes a Home foi consultada.
class _GuardianHomeLoader implements HomeLoader<GuardianHomeData> {
  int fetchCount = 0;

  @override
  Future<GuardianHomeData> fetchHome() async {
    fetchCount++;
    return const GuardianHomeData(
      guardianName: 'Carlos Lima',
      todayTrainings: [],
      weeklyCompleted: 0,
      weeklyPlanned: 0,
      monthlyCompleted: 0,
      monthlyPlanned: 0,
      allTimeCompleted: 0,
      horses: [],
      totalHorses: 0,
      trainers: [],
    );
  }
}
