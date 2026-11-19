// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Atualização do teste da Sidebar para a rota modular do cadastro;
// serviços de produção não são inicializados durante o teste de navegação.
//
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura do link "Cadastrar cavalo" na barra lateral do treinador.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura do link da barra lateral do treinador que abre o
// formulário de cadastro de exercícios.
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
import 'package:horse_life/features/exercises/presentation/screens/exercise_type_selection_screen.dart';
import 'package:horse_life/features/home/application/controllers/home_loader.dart';
import 'package:horse_life/features/home/data/models/trainer_home_data.dart';
import 'package:horse_life/features/home/presentation/screens/trainer/trainer_home_screen.dart';
import 'package:horse_life/features/horses/presentation/screens/horse_relationship_screen.dart';
import 'package:horse_life/features/horses/presentation/routes/horse_registration_flow_route.dart';
import 'package:horse_life/features/horses/data/repositories/mock_horse_registration_repository.dart';
import 'package:horse_life/core/widgets/trainer_sidebar.dart';

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

  // --- Navegação para cadastro de exercícios --------------------------------
  testWidgets(
    'opens exercise creation flow when tapping Cadastrar exercício in TrainerSidebar',
    (tester) async {
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

      await tester.tap(find.byTooltip('Abrir menu'));
      await tester.pumpAndSettle();

      final createExerciseTile = find.byKey(
        const Key('trainer-sidebar-create-exercise'),
      );
      expect(createExerciseTile, findsOneWidget);
      expect(find.text('Cadastrar exercício'), findsOneWidget);

      await tester.tap(createExerciseTile);
      await tester.pumpAndSettle();

      expect(find.byType(ExerciseTypeSelectionScreen), findsOneWidget);
      expect(find.text('Tipo de exercício'), findsOneWidget);
    },
  );

  // --- Navegação para cadastro de cavalos -----------------------------------
  testWidgets(
    'opens horse registration flow when tapping Cadastrar cavalo in TrainerSidebar',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          theme: AppTheme.light,
          home: Scaffold(
            appBar: AppBar(title: const Text('Teste da Sidebar')),
            drawer: TrainerSidebar(
              homeFuture: _TrainerHomeLoader().fetchHome(),
              onLogout: () async {},
              onRegisterHorse: () {
                navigatorKey.currentState!.push(
                  HorseRegistrationFlowRoute.build(
                    repository: const MockHorseRegistrationRepository(),
                  ),
                );
              },
            ),
            body: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffold.openDrawer();
      await tester.pumpAndSettle();

      final registerHorseTile = find.byKey(
        const Key('trainer-sidebar-register-horse'),
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
