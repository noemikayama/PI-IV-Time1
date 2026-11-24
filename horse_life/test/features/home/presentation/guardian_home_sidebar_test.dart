// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição de teste cobrindo habilitação e execução do botão Iniciar
// treino na seção Treinos do dia da Home do responsável com resolução do planId.
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
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';
import 'package:horse_life/features/training/data/models/training_execution_data.dart';
import 'package:horse_life/features/training/data/repositories/training_agenda_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_execution_repository.dart';
import 'package:horse_life/features/training/presentation/screens/training_execution_screen.dart';

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

  testWidgets(
    'enables Iniciar treino in Treinos do dia and opens TrainingExecutionScreen with resolved planId',
    (tester) async {
      final executionLoader = _RecordingTrainingExecutionLoader();
      final agendaLoader = _GuardianAgendaLoader();
      final submitter = _StubTrainingCompletionSubmitter();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: GuardianHomeScreen(
            loader: _GuardianHomeWithTrainingLoader(),
            agendaLoader: agendaLoader,
            trainingExecutionLoader: executionLoader,
            trainingCompletionSubmitter: submitter,
            onLogout: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final startButtonFinder = find.widgetWithText(
        ElevatedButton,
        'Iniciar treino',
      );
      expect(startButtonFinder, findsOneWidget);
      final startButton = tester.widget<ElevatedButton>(startButtonFinder);
      expect(startButton.onPressed, isNotNull);

      await tester.tap(startButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(TrainingExecutionScreen), findsOneWidget);
      expect(executionLoader.lastReference, isNotNull);
      expect(executionLoader.lastReference!.recordId, 'rec-1');
      expect(executionLoader.lastReference!.planId, 'plan-1');
      expect(executionLoader.lastReference!.date, DateTime(2026, 11, 23));
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

class _GuardianHomeWithTrainingLoader implements HomeLoader<GuardianHomeData> {
  @override
  Future<GuardianHomeData> fetchHome() async => const GuardianHomeData(
    guardianName: 'Noemi Kayama',
    todayTrainings: [
      GuardianTraining(
        recordId: 'rec-1',
        title: 'Fortalecimento',
        horseName: 'Twilight Sparkle',
        trainerName: 'Noemia Kayama',
        durationMinutes: 380,
        planName: 'Plano de verão 2026/2027',
        status: 'PLANEJADO',
      ),
    ],
    weeklyCompleted: 0,
    weeklyPlanned: 1,
    monthlyCompleted: 0,
    monthlyPlanned: 1,
    allTimeCompleted: 0,
    horses: ['Twilight Sparkle'],
    totalHorses: 1,
    trainers: ['Noemia Kayama'],
  );
}

class _GuardianAgendaLoader implements TrainingAgendaLoader {
  @override
  Future<TrainingAgendaData> fetchAgenda({DateTime? date}) async {
    final today = DateTime(2026, 11, 23);
    return TrainingAgendaData(
      audience: TrainingAgendaAudience.guardian,
      today: today,
      weekStart: today,
      weekEnd: today.add(const Duration(days: 6)),
      activePlansCount: 1,
      plans: [
        TrainingAgendaPlan(
          id: 'plan-1',
          trainingName: 'Fortalecimento',
          horseName: 'Twilight Sparkle',
          trainerName: 'Noemia Kayama',
          planName: 'Plano de verão 2026/2027',
          date: today,
          status: TrainingAgendaStatus.planned,
        ),
      ],
      weekTrainings: [
        TrainingAgendaEntry(
          id: 'rec-1',
          title: 'Fortalecimento',
          horseName: 'Twilight Sparkle',
          trainerName: 'Noemia Kayama',
          planName: 'Plano de verão 2026/2027',
          date: today,
          durationMinutes: 380,
          status: TrainingAgendaStatus.planned,
          action: TrainingAgendaAction.start,
        ),
      ],
      todayTrainings: const [],
      history: const [],
    );
  }
}

class _RecordingTrainingExecutionLoader implements TrainingExecutionLoader {
  TrainingExecutionReference? lastReference;

  @override
  Future<TrainingExecutionData> fetchTraining(
    TrainingExecutionReference reference,
  ) async {
    lastReference = reference;
    return TrainingExecutionData(
      recordId: reference.recordId,
      title: reference.title,
      durationMinutes: reference.durationMinutes,
      description: 'Descrição do treino',
      guidelines: const [],
      exercises: const [],
      isFinished: false,
      canStart: true,
    );
  }
}

class _StubTrainingCompletionSubmitter
    implements TrainingCompletionSubmitter {
  @override
  Future<TrainingCompletionResult> submit(TrainingCompletionInput input) async =>
      const TrainingCompletionResult(status: 'REALIZADO');
}
