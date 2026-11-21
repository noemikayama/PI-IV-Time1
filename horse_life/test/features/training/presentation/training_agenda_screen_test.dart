// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão do teste de regressão que verifica a transferência do
// círculo colorido para o novo dia selecionado no calendário e documentação do
// cenário e da inspeção visual usada na asserção.
//
// Data: 18/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da agenda semanal, estados vazios, perfis de acesso,
// navegação por semanas, modal de planos ativos e menu flutuante profissional.
// Documentação das fábricas, cenários e dublês usados nos testes.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/home/application/controllers/home_loader.dart';
import 'package:horse_life/features/home/data/models/guardian_home_data.dart';
import 'package:horse_life/features/home/data/models/trainer_home_data.dart';
import 'package:horse_life/features/home/presentation/screens/guardian/guardian_home_screen.dart';
import 'package:horse_life/features/home/presentation/screens/trainer/trainer_home_screen.dart';
import 'package:horse_life/features/profile/data/models/guardian_profile_data.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';
import 'package:horse_life/features/training/presentation/screens/training_agenda_screen.dart';

void main() {
  // Data fixa que torna previsíveis a semana, os rótulos e as chaves dos dias.
  final selectedDate = DateTime(2026, 11, 18);

  // Cria um treino com os valores mínimos variáveis de cada cenário.
  TrainingAgendaEntry entry({
    required String id,
    required String horse,
    required TrainingAgendaStatus status,
    required TrainingAgendaAction action,
  }) {
    return TrainingAgendaEntry(
      id: id,
      title: 'Treino $id',
      horseName: horse,
      trainerName: 'Carlos Mendes',
      planName: 'Plano $id',
      date: selectedDate,
      durationMinutes: 45,
      status: status,
      action: action,
    );
  }

  // Cria planos numerados para validar listagem, modal e rolagem.
  TrainingAgendaPlan plan(int index) => TrainingAgendaPlan(
    id: '$index',
    trainingName: 'Treinamento $index',
    horseName: 'Cavalo $index',
    trainerName: 'Carlos Mendes',
    planName: 'Plano $index',
    date: selectedDate,
    status: TrainingAgendaStatus.planned,
  );

  // Envolve a agenda com o tema real e expõe apenas as dependências relevantes
  // para cada teste de widget.
  Widget buildAgenda({
    required List<TrainingAgendaEntry> trainings,
    List<TrainingAgendaPlan>? plans,
    TrainingAgendaAudience audience = TrainingAgendaAudience.guardian,
    TrainingAgendaEntryCallback? onStart,
    TrainingAgendaEntryCallback? onView,
    ValueChanged<TrainingAgendaPlan>? onViewPlan,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: TrainingAgendaScreen(
          activePlansCount: plans?.length ?? 0,
          plans: plans ?? const [],
          trainings: trainings,
          audience: audience,
          initialDate: selectedDate,
          onViewPlan: onViewPlan,
          onStartTraining: onStart,
          onViewTraining: onView,
        ),
      ),
    );
  }

  testWidgets('uses the action assigned to each horse and invokes callbacks', (
    tester,
  ) async {
    String? started;
    String? viewed;
    await tester.pumpWidget(
      buildAgenda(
        trainings: [
          entry(
            id: 'atleta',
            horse: 'Trovão',
            status: TrainingAgendaStatus.planned,
            action: TrainingAgendaAction.start,
          ),
          entry(
            id: 'proprietario',
            horse: 'Lua',
            status: TrainingAgendaStatus.planned,
            action: TrainingAgendaAction.view,
          ),
        ],
        onStart: (training) => started = training.id,
        onView: (training) => viewed = training.id,
      ),
    );

    expect(find.text('Iniciar treino'), findsOneWidget);
    await tester.ensureVisible(find.text('Iniciar treino'));
    await tester.tap(find.text('Iniciar treino'));
    expect(started, 'atleta');

    await tester.ensureVisible(find.byType(PageView));
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Ver treino'), findsOneWidget);
    await tester.tap(find.text('Ver treino'));
    expect(viewed, 'proprietario');
  });

  testWidgets('limits the plan viewport to three cards and scrolls overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildAgenda(
        trainings: [
          entry(
            id: 'planejado',
            horse: 'Trovão',
            status: TrainingAgendaStatus.planned,
            action: TrainingAgendaAction.start,
          ),
        ],
        plans: List.generate(4, plan),
      ),
    );

    final planList = find.byType(ListView);
    expect(planList, findsOneWidget);
    expect(tester.getSize(planList).height, 696);

    await tester.ensureVisible(planList);
    await tester.drag(planList, const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Treinamento 3'), findsOneWidget);
  });

  testWidgets('shows executed items and navigates seven days per arrow tap', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildAgenda(
        trainings: [
          entry(
            id: 'concluido',
            horse: 'Trovão',
            status: TrainingAgendaStatus.completed,
            action: TrainingAgendaAction.start,
          ),
          entry(
            id: 'planejado',
            horse: 'Lua',
            status: TrainingAgendaStatus.planned,
            action: TrainingAgendaAction.view,
          ),
        ],
      ),
    );

    expect(find.text('Realizado'), findsOneWidget);
    expect(find.text('Treino concluido'), findsNWidgets(2));

    expect(
      find.byKey(const ValueKey<String>('agenda-day-2026-11-16')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('agenda-next-week')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('agenda-day-2026-11-23')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('agenda-day-2026-11-16')),
      findsNothing,
    );

    await tester.tap(find.byKey(const Key('agenda-next-week')));
    await tester.pump();
    expect(find.text('dezembro 2026'), findsOneWidget);
  });

  // Reproduz a seleção de um dia vazio após um dia com treino e inspeciona o
  // preenchimento real dos círculos, não apenas o estado semântico do widget.
  testWidgets('moves the colored date circle to the selected day', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildAgenda(
        trainings: [
          entry(
            id: 'planejado',
            horse: 'Trovão',
            status: TrainingAgendaStatus.planned,
            action: TrainingAgendaAction.start,
          ),
        ],
      ),
    );

    // Lê a cor do AnimatedContainer pertencente à chave estável de cada dia.
    Color? dateCircleColor(String dateKey) {
      final day = find.byKey(ValueKey<String>(dateKey));
      final circle = find.descendant(
        of: day,
        matching: find.byType(AnimatedContainer),
      );
      final decoration = tester.widget<AnimatedContainer>(circle).decoration;
      return (decoration as BoxDecoration).color;
    }

    expect(dateCircleColor('agenda-day-2026-11-18'), isNotNull);
    expect(dateCircleColor('agenda-day-2026-11-19'), isNull);

    await tester.tap(
      find.byKey(const ValueKey<String>('agenda-day-2026-11-19')),
    );
    await tester.pumpAndSettle();

    expect(dateCircleColor('agenda-day-2026-11-18'), isNull);
    expect(dateCircleColor('agenda-day-2026-11-19'), isNotNull);
  });

  testWidgets('shows all empty states and renders exactly one week', (
    tester,
  ) async {
    await tester.pumpWidget(buildAgenda(trainings: const []));

    final calendarDays = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return widget is InkWell &&
          key is ValueKey<String> &&
          key.value.startsWith('agenda-day-');
    });

    expect(calendarDays, findsNWidgets(7));
    expect(find.text('Nenhum treino marcado'), findsNWidgets(2));
    expect(find.text('Nenhuma execução registrada'), findsOneWidget);
    expect(
      find.text(
        'Não há nenhum treino agendado no período selecionado.\n'
        'Aproveite para descansar ou entre em contato com um treinador para '
        'que ele monte o plano ideal para você.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Execute um treino para registrar o progresso do seu animal e poder '
        'obter feedbacks do treinador.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the completed-day empty state', (tester) async {
    await tester.pumpWidget(
      buildAgenda(
        trainings: [
          entry(
            id: 'concluido',
            horse: 'Trovão',
            status: TrainingAgendaStatus.completed,
            action: TrainingAgendaAction.start,
          ),
        ],
      ),
    );

    expect(find.text('Todos concluídos'), findsOneWidget);
    expect(
      find.text(
        'Continue assim! Consistência e dedicação são o caminho para o sucesso.',
      ),
      findsOneWidget,
    );
    expect(find.text('Iniciar treino'), findsNothing);
  });

  testWidgets('guardian active plans sheet shows trainer and horse', (
    tester,
  ) async {
    String? selectedPlan;
    await tester.pumpWidget(
      buildAgenda(
        trainings: const [],
        plans: [plan(0)],
        onViewPlan: (selected) => selectedPlan = selected.id,
      ),
    );

    await tester.tap(find.text('Ver planos'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('active-plans-sheet')), findsOneWidget);
    expect(find.text('Planos ativos'), findsOneWidget);
    expect(find.text('Plano 0'), findsOneWidget);
    expect(find.text('Carlos Mendes'), findsOneWidget);
    expect(find.text('Cavalo 0'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('active-plan-0')));
    await tester.pumpAndSettle();
    expect(selectedPlan, '0');
    expect(find.byKey(const Key('active-plans-sheet')), findsNothing);
  });

  testWidgets('trainer active plans sheet hides trainer identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildAgenda(
        audience: TrainingAgendaAudience.trainer,
        trainings: const [],
        plans: [plan(0)],
      ),
    );

    await tester.tap(find.text('Ver planos'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('active-plans-sheet')), findsOneWidget);
    expect(find.text('Plano 0'), findsOneWidget);
    expect(find.text('Cavalo 0'), findsOneWidget);
    expect(find.text('Carlos Mendes'), findsNothing);
  });

  testWidgets(
    'guardian agenda gives athlete precedence over owner-only relationship',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: GuardianHomeScreen(
            onLogout: () async {},
            loader: _GuardianAgendaLoader(),
            guardianProfileLoader: () async => const GuardianProfileData(
              name: 'Maria',
              email: 'maria@email.com',
              horses: [
                GuardianProfileHorse(
                  name: 'Trovão',
                  relationship: 'Proprietário e atleta',
                ),
                GuardianProfileHorse(name: 'Lua', relationship: 'Proprietário'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Treinos'));
      await tester.pumpAndSettle();
      expect(find.text('Iniciar treino'), findsOneWidget);

      await tester.ensureVisible(find.byType(PageView));
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Ver treino'), findsOneWidget);
    },
  );

  testWidgets('trainer agenda shows one week and opens the creation menu', (
    tester,
  ) async {
    var plans = 0;
    var trainings = 0;
    var exercises = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TrainerHomeScreen(
          onLogout: () async {},
          loader: const _TrainerAgendaLoader(),
          onCreateTrainingPlan: () => plans++,
          onCreateTraining: () => trainings++,
          onCreateExercise: () => exercises++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Treinos'));
    await tester.pumpAndSettle();

    final calendarDays = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return widget is InkWell &&
          key is ValueKey<String> &&
          key.value.startsWith('agenda-day-');
    });
    expect(calendarDays, findsNWidgets(7));
    expect(find.text('Ver treino'), findsOneWidget);
    expect(find.text('0 minutos'), findsNothing);
    expect(find.byKey(const Key('trainer-agenda-fab')), findsOneWidget);

    await tester.tap(find.byKey(const Key('trainer-agenda-fab')));
    await tester.pumpAndSettle();
    expect(find.text('Plano de treinos'), findsOneWidget);
    expect(find.text('Treinamento'), findsOneWidget);
    expect(find.text('Exercício'), findsOneWidget);

    await tester.tap(find.byKey(const Key('trainer-agenda-create-plan')));
    await tester.pumpAndSettle();
    expect(plans, 1);
    expect(find.text('Plano de treinos'), findsNothing);

    await tester.tap(find.byKey(const Key('trainer-agenda-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trainer-agenda-create-training')));
    await tester.pumpAndSettle();
    expect(trainings, 1);

    await tester.tap(find.byKey(const Key('trainer-agenda-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trainer-agenda-create-exercise')));
    await tester.pumpAndSettle();
    expect(exercises, 1);
  });

  testWidgets('trainer agenda uses the professional empty states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TrainerHomeScreen(
          onLogout: () async {},
          loader: const _TrainerAgendaLoader(empty: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Treinos'));
    await tester.pumpAndSettle();

    expect(find.text('Ver planos'), findsNothing);
    expect(find.text('Nenhum treino marcado'), findsNWidgets(2));
    expect(
      find.text(
        'Não há nenhum treino agendado no período selecionado.\n'
        'Aproveite para se organizar ou aguarde até que algum proprietário '
        'vincule você ao cavalo dele e você possa prescrever seus treinos.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Aproveite o dia para responder feedbacks ou montar novos treinos.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Aguarde até que algum atleta execute o treino para que você possa ter '
        'acesso aos dados e escrever feedbacks.',
      ),
      findsOneWidget,
    );
  });
}

// Dublê da Home do responsável com dois vínculos de cavalo distintos.
class _GuardianAgendaLoader implements HomeLoader<GuardianHomeData> {
  @override
  Future<GuardianHomeData> fetchHome() async => const GuardianHomeData(
    guardianName: 'Maria',
    todayTrainings: [
      GuardianTraining(
        title: 'Transições',
        horseName: 'Trovão',
        trainerName: 'Carlos',
        durationMinutes: 45,
        planName: 'Condicionamento',
        recordId: '1',
        status: 'PLANEJADO',
      ),
      GuardianTraining(
        title: 'Salto',
        horseName: 'Lua',
        trainerName: 'Carlos',
        durationMinutes: 30,
        planName: 'Percurso',
        recordId: '2',
        status: 'PLANEJADO',
      ),
    ],
    weeklyCompleted: 0,
    weeklyPlanned: 2,
    monthlyCompleted: 0,
    monthlyPlanned: 2,
    allTimeCompleted: 0,
    horses: ['Trovão', 'Lua'],
    trainers: ['Carlos'],
  );
}

// Dublê da Home profissional, configurável com ou sem agenda ativa.
class _TrainerAgendaLoader implements HomeLoader<TrainerHomeData> {
  const _TrainerAgendaLoader({this.empty = false});

  final bool empty;

  @override
  Future<TrainerHomeData> fetchHome() async => TrainerHomeData(
    trainerName: 'Carlos',
    specialty: 'Salto',
    todayTrainings: empty
        ? const []
        : const [
            TrainerTraining(
              id: 'treino-1',
              title: 'Trabalho de transições',
              horseName: 'Trovão',
              planName: 'Condicionamento',
              status: 'PLANEJADO',
            ),
          ],
    weeklyFeedbacksDone: 0,
    weeklyFeedbacksTotal: 0,
    activePlans: empty ? 0 : 1,
    weeklyTrainingsCompleted: 0,
    weeklyTrainingsPlanned: empty ? 0 : 1,
    createdExercises: 0,
    horses: const [],
    clients: const [],
  );
}
