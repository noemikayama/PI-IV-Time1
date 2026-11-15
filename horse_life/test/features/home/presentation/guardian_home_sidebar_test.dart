// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
import 'package:horse_life/features/horses/presentation/screens/horse_registration_screen.dart';

void main() {
  testWidgets(
    'opens horse registration flow when tapping Cadastrar cavalo in GuardianSidebar',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: GuardianHomeScreen(
            loader: _GuardianHomeLoader(),
            onLogout: () async {},
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

      expect(find.byType(HorseRegistrationScreen), findsOneWidget);
      expect(find.text('Relação com o cavalo'), findsOneWidget);
    },
  );
}

class _GuardianHomeLoader implements HomeLoader<GuardianHomeData> {
  @override
  Future<GuardianHomeData> fetchHome() async => const GuardianHomeData(
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
