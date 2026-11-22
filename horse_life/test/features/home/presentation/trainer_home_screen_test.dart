// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura da filtragem defensiva de treinos CANCELADO na agenda e na Home.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura do link "Cadastrar plano de treino" na barra lateral
// do treinador abrindo o fluxo de cadastro de planos de treinamento.
//
// Data: 18/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Atualização do teste da Sidebar para a rota modular do cadastro;
// serviços de produção não são inicializados durante o teste de navegação.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura do link "Cadastrar treinamento" na barra lateral do
// treinador abrindo o fluxo de cadastro de treinamentos.
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
import '../../../support/features/horses/data/repositories/mock_horse_registration_repository.dart';
import 'package:horse_life/core/widgets/trainer_sidebar.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_title_screen.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_title_screen.dart';

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

  // --- Navegação para cadastro de treinamentos ------------------------------
  testWidgets(
    'opens training registration flow when tapping Cadastrar treinamento in TrainerSidebar',
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

      final createTrainingTile = find.byKey(
        const Key('trainer-sidebar-create-training'),
      );
      expect(createTrainingTile, findsOneWidget);
      expect(find.text('Cadastrar treinamento'), findsOneWidget);

      await tester.tap(createTrainingTile);
      await tester.pumpAndSettle();

      expect(find.byType(TrainingTitleScreen), findsOneWidget);
      expect(find.text('Título do treinamento'), findsOneWidget);
    },
  );

  // --- Navegação para cadastro de planos de treinamento ---------------------
  testWidgets(
    'opens training plan registration flow when tapping Cadastrar plano de treino in TrainerSidebar',
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

      final createPlanTile = find.byKey(
        const Key('trainer-sidebar-create-training-plan'),
      );
      expect(createPlanTile, findsOneWidget);
      expect(find.text('Cadastrar plano de treino'), findsOneWidget);

      await tester.tap(createPlanTile);
      await tester.pumpAndSettle();

      expect(find.byType(TrainingPlanTitleScreen), findsOneWidget);
      expect(find.text('Título do plano'), findsOneWidget);
    },
  );

  testWidgets(
    'ignora treinos com status CANCELADO tanto na Home quanto na aba de treinos da agenda',
    (tester) async {
      final loader = _TrainerHomeWithCanceledTrainingLoader();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TrainerHomeScreen(
            loader: loader,
            onLogout: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Na Home, não deve exibir o treino cancelado
      expect(find.text('Treino Cancelado Indevido'), findsNothing);
      expect(find.text('Treino Ativo Válido'), findsOneWidget);

      // Na aba de Treinos (Agenda), também não deve exibir o cancelado
      await tester.tap(find.text('Treinos'));
      await tester.pumpAndSettle();

      expect(find.text('Treino Cancelado Indevido'), findsNothing);
      expect(find.text('Treino Ativo Válido'), findsWidgets);
    },
  );
}

class _TrainerHomeWithCanceledTrainingLoader
    implements HomeLoader<TrainerHomeData> {
  @override
  Future<TrainerHomeData> fetchHome() async => const TrainerHomeData(
    trainerName: 'Ana Souza',
    specialty: 'Adestramento',
    todayTrainings: [
      TrainerTraining(
        id: 'rec-valid',
        title: 'Treino Ativo Válido',
        horseName: 'Valente',
        planName: 'Plano Regular',
        status: 'PLANEJADO',
      ),
      TrainerTraining(
        id: 'rec-canceled',
        title: 'Treino Cancelado Indevido',
        horseName: 'Valente',
        planName: 'Plano Cancelado',
        status: 'CANCELADO',
      ),
    ],
    weeklyFeedbacksDone: 0,
    weeklyFeedbacksTotal: 0,
    activePlans: 1,
    weeklyTrainingsCompleted: 0,
    weeklyTrainingsPlanned: 1,
    createdExercises: 0,
    horses: [],
    clients: [],
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
