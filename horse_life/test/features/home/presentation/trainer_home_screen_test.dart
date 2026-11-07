// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do cenário de navegação e do carregador falso da Home
// do treinador.
//
// Data: 04/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do teste da navegação para o perfil do treinador, validando
// a ocultação do conteúdo da Home e a permanência da barra superior.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/features/home/application/controllers/home_loader.dart';
import 'package:horse_life/features/home/data/models/trainer_home_data.dart';
import 'package:horse_life/features/home/presentation/screens/trainer/trainer_home_screen.dart';

void main() {
  // --- Navegação para o perfil ----------------------------------------------
  // Valida o estado temporário da aba: a estrutura permanece, mas os cards da
  // Home são retirados até a implementação do perfil do treinador.
  testWidgets('shows a blank trainer profile body from the bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TrainerHomeScreen(
          loader: _TrainerHomeLoader(),
          onLogout: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Treinos do dia'), findsOneWidget);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeAppBar), findsOneWidget);
    expect(find.text('Treinos do dia'), findsNothing);
    expect(find.text('Perfil'), findsOneWidget);
  });
}

/// Carregador estável que evita acesso a serviços externos durante o teste.
class _TrainerHomeLoader implements HomeLoader<TrainerHomeData> {
  @override
  Future<TrainerHomeData> fetchHome() async => const TrainerHomeData(
    trainerName: 'Ana Souza',
    specialty: 'Adestramento',
    todayTrainings: [],
    weeklyFeedbacksDone: 0,
    weeklyFeedbacksTotal: 0,
    activePlans: 0,
    weeklyTrainingsCompleted: 0,
    weeklyTrainingsPlanned: 0,
    createdExercises: 0,
    horses: [],
    clients: [],
  );
}
