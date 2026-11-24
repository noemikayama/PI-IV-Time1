// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do treino diário por perfil, abertura da execução pelo
// atleta, quebra de linha do plano ativo e navegação para cadastrar um plano.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação e cobertura das permissões por usuário, chamada de
// deleteHorse, estado de progresso, timeouts e edição do perfil.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura dos cards recolhíveis, visual dos vínculos, modal
// de confirmação da exclusão, menu inferior, galeria e edição via updateHorse.
// Cobertura da permissão do proprietário e do modal compartilhado de inclusão.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura dos dados do perfil e da permissão de edição.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/horses/data/models/horse_profile_data.dart';
import 'package:horse_life/features/horses/data/repositories/horse_profile_repository.dart';
import 'package:horse_life/features/horses/presentation/screens/horse_profile_edit_screen.dart';
import 'package:horse_life/features/horses/presentation/screens/horse_profile_screen.dart';
import 'package:horse_life/features/horses/presentation/services/horse_image_selection_service.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';
import 'package:horse_life/features/training/data/models/training_execution_data.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_execution_repository.dart';
import 'package:horse_life/features/training/presentation/screens/active_training_screen.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_title_screen.dart';

void main() {
  // Usa a menor largura suportada para transformar o overflow em regressão.
  testWidgets('quebra o nome longo do plano ativo sem overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final plan = HorseProfilePlan(
      id: 'plan-1',
      title:
          'Plano de condicionamento físico avançado para competições nacionais',
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2026, 11, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(
          horseId: 'horse-1',
          repository: _FakeRepository(_horse(currentPlan: plan)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -420));
    await tester.pumpAndSettle();

    final planLink = find.byKey(const Key('horse-current-plan-link'));
    expect(planLink, findsOneWidget);
    await tester.ensureVisible(planLink);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining(plan.title), findsOneWidget);
  });

  testWidgets('mostra dados e edição para o proprietário', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(
          horseId: 'horse-1',
          repository: _FakeRepository(
            _horse(responsibilities: const ['PROPRIETARIO']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trovão'), findsOneWidget);
    expect(find.textContaining('Microchip:'), findsOneWidget);
    expect(find.byKey(const Key('edit-horse-profile-button')), findsOneWidget);
    expect(
      find.byKey(const Key('edit-horse-relationships-button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('edit-horse-relationships-button')));
    await tester.pumpAndSettle();

    expect(find.text('Edição de vínculos'), findsOneWidget);
    expect(find.text('Treinador'), findsOneWidget);
    expect(find.text('Atleta'), findsOneWidget);
  });

  testWidgets(
    'cancelar a confirmação não grava e restaura os vínculos do banco',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _FakeRepository(
        _horse(
          responsibilities: const ['PROPRIETARIO'],
          athlete: const HorseProfilePerson(id: 'athlete-1', name: 'Beatriz'),
          trainers: const [HorseProfilePerson(id: 'trainer-1', name: 'Carlos')],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HorseProfileScreen(horseId: 'horse-1', repository: repository),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('edit-horse-relationships-button')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Carlos'), findsWidgets);

      await tester.tap(
        find.byKey(const Key('remove-horse-trainer-relationship')),
      );
      await tester.tap(
        find.byKey(const Key('save-horse-relationships-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Tem certeza que quer desvincular esse usuário?'),
        findsOneWidget,
      );
      expect(repository.relationshipUpdateCalls, 0);
      await tester.tap(
        find.byKey(const Key('destructive-dialog-cancel-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('horse-relationships-dialog')),
        findsOneWidget,
      );
      expect(find.text('Carlos'), findsWidgets);
      expect(
        find.byKey(const Key('remove-horse-trainer-relationship')),
        findsOneWidget,
      );
      expect(repository.relationshipUpdateCalls, 0);
    },
  );

  testWidgets('salva e-mails novos sem abrir alerta de remoção', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRepository(
      _horse(responsibilities: const ['PROPRIETARIO']),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(horseId: 'horse-1', repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-horse-relationships-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('horse-trainer-relationship-field')),
      'treinador@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('horse-athlete-relationship-field')),
      'atleta@example.com',
    );
    await tester.tap(find.byKey(const Key('save-horse-relationships-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('destructive-confirmation-dialog')),
      findsNothing,
    );
    expect(repository.relationshipUpdateCalls, 1);
    expect(repository.lastTrainerEmail, 'treinador@example.com');
    expect(repository.lastAthleteEmail, 'atleta@example.com');
  });

  testWidgets('oculta edição para treinador', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(
          horseId: 'horse-1',
          currentUserId: 'trainer-1',
          isTrainer: true,
          repository: _FakeRepository(
            _horse(
              trainers: const [
                HorseProfilePerson(id: 'trainer-1', name: 'Bruno'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trovão'), findsOneWidget);
    expect(find.byKey(const Key('edit-horse-profile-button')), findsNothing);
    expect(
      find.byKey(const Key('edit-horse-relationships-button')),
      findsNothing,
    );
    expect(find.byKey(const Key('add-horse-limitation-button')), findsNothing);
    expect(find.byKey(const Key('add-horse-health-note-button')), findsNothing);
    expect(find.byKey(const Key('add-horse-injury-button')), findsNothing);
  });

  for (final responsibility in const ['PROPRIETARIO', 'ATLETA']) {
    testWidgets(
      'mostra empty states de plano e avaliações para $responsibility',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: HorseProfileScreen(
              horseId: 'horse-1',
              repository: _FakeRepository(
                _horse(responsibilities: [responsibility]),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Plano atual'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('horse-plan-empty-state')), findsOneWidget);
        expect(find.text('Nenhum plano ativo'), findsOneWidget);
        expect(find.byKey(const Key('add-horse-plan-button')), findsNothing);
        expect(
          find.textContaining('prescrever a rotina ideal para ele'),
          findsOneWidget,
        );

        await tester.tap(find.text('Avaliações'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('horse-evaluations-empty-state')),
          findsOneWidget,
        );
        expect(find.text('Nenhuma avaliação realizada'), findsOneWidget);
        expect(
          find.byKey(const Key('add-horse-evaluation-button')),
          findsNothing,
        );
        expect(
          find.textContaining('condição física do seu cavalo'),
          findsOneWidget,
        );
        if (responsibility == 'ATLETA') {
          expect(
            find.byKey(const Key('edit-horse-profile-button')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('edit-horse-relationships-button')),
            findsNothing,
          );
          expect(find.byKey(const Key('remove-horse-button')), findsNothing);
        }
      },
    );
  }

  // Exercita as três perspectivas que recebem ações distintas no treino diário.
  for (final scenario in const [
    (
      name: 'atleta com permissão remota desatualizada',
      responsibility: 'ATLETA',
      action: HorseProfileTrainingAction.view,
      personRole: 'TREINADOR',
      personName: 'Carlos',
      button: 'Iniciar treino',
      isTrainer: false,
    ),
    (
      name: 'proprietário',
      responsibility: 'PROPRIETARIO',
      action: HorseProfileTrainingAction.view,
      personRole: 'TREINADOR',
      personName: 'Carlos',
      button: 'Ver treino',
      isTrainer: false,
    ),
    (
      name: 'treinador',
      responsibility: '',
      action: HorseProfileTrainingAction.view,
      personRole: 'ATLETA',
      personName: 'Beatriz',
      button: 'Ver treino',
      isTrainer: true,
    ),
  ]) {
    testWidgets('mostra o treino do dia para ${scenario.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final plan = HorseProfilePlan(
        id: 'plan-1',
        title: 'Plano A',
        startDate: DateTime(2026, 11, 1),
        endDate: DateTime(2026, 11, 30),
        todayTraining: HorseProfileDayTraining(
          recordId: 'record-1',
          name: 'Trabalho de transições',
          planName: 'Plano A',
          durationMinutes: 45,
          personRole: scenario.personRole,
          personName: scenario.personName,
          status: 'PLANEJADO',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: HorseProfileScreen(
            horseId: 'horse-1',
            isTrainer: scenario.isTrainer,
            repository: _FakeRepository(
              _horse(
                responsibilities: scenario.responsibility.isEmpty
                    ? const []
                    : [scenario.responsibility],
                currentPlan: plan,
                trainingAction: scenario.action,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plano atual'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('horse-today-training-card')),
        findsOneWidget,
      );
      expect(find.text('Trabalho de transições'), findsOneWidget);
      expect(find.text(scenario.personName), findsOneWidget);
      expect(find.text(scenario.button), findsOneWidget);
    });
  }

  // Confirma o atalho do atleta até a execução sem passar pela tela consultiva.
  testWidgets('atleta inicia o treino diretamente pelo perfil', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final plan = HorseProfilePlan(
      id: 'plan-1',
      title: 'Plano A',
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2026, 11, 30),
      todayTraining: const HorseProfileDayTraining(
        recordId: 'record-1',
        name: 'Trabalho de transições',
        planName: 'Plano A',
        durationMinutes: 45,
        personRole: 'TREINADOR',
        personName: 'Carlos',
        status: 'PLANEJADO',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(
          horseId: 'horse-1',
          repository: _FakeRepository(
            _horse(
              responsibilities: const ['ATLETA'],
              currentPlan: plan,
              trainingAction: HorseProfileTrainingAction.start,
            ),
          ),
          trainingLoader: const _FakeTodayTrainingLoader(),
          completionSubmitter: const _FakeTrainingSubmitter(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plano atual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iniciar treino'));
    await tester.pumpAndSettle();

    expect(find.byType(ActiveTrainingScreen), findsOneWidget);
    expect(find.text('Ver informações do treino'), findsOneWidget);
  });

  testWidgets('mostra ações de plano e avaliação somente para treinador', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(
          horseId: 'horse-1',
          currentUserId: 'trainer-1',
          isTrainer: true,
          repository: _FakeRepository(
            _horse(
              trainers: const [
                HorseProfilePerson(id: 'trainer-1', name: 'Carlos'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plano atual'));
    await tester.pumpAndSettle();
    final addPlan = find.byKey(const Key('add-horse-plan-button'));
    expect(addPlan, findsOneWidget);
    expect(find.text('Adicionar plano'), findsOneWidget);
    await tester.tap(find.text('Adicionar plano'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingPlanTitleScreen), findsOneWidget);
    expect(find.text('Título do plano'), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Avaliações'));
    await tester.pumpAndSettle();
    final addEvaluation = find.byKey(const Key('add-horse-evaluation-button'));
    expect(addEvaluation, findsOneWidget);
    expect(find.text('Nova avaliação'), findsOneWidget);
    await tester.tap(find.text('Nova avaliação'));
    await tester.pump();
    expect(
      find.byKey(const Key('horse-evaluations-empty-state')),
      findsOneWidget,
    );
  });

  testWidgets('abre o formulário para adicionar uma limitação', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRepository(
      _horse(responsibilities: const ['PROPRIETARIO']),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(horseId: 'horse-1', repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('add-horse-limitation-button'));
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('Adicionar limitação'), findsOneWidget);
    expect(find.text('Descreva aqui'), findsOneWidget);
    expect(find.byKey(const Key('horse-text-entry-dialog')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('horse-text-entry-field')),
      'Sensibilidade no casco posterior esquerdo.',
    );
    await tester.pump();
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('horse-entry-dialog-save-button')),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('horse-entry-dialog-save-button')));
    await tester.pumpAndSettle();

    expect(
      repository.lastUpdate?.physicalLimitations?.added,
      contains('Sensibilidade no casco posterior esquerdo.'),
    );
  });

  testWidgets('recolhe as seções e apresenta os vínculos como no protótipo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(
          horseId: 'horse-1',
          repository: _FakeRepository(
            _horse(
              responsibilities: const ['PROPRIETARIO'],
              athlete: const HorseProfilePerson(
                id: 'athlete-1',
                name: 'Beatriz',
              ),
              trainers: const [
                HorseProfilePerson(id: 'trainer-1', name: 'Carlos'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Atleta'), findsOneWidget);
    expect(find.text('Beatriz'), findsOneWidget);
    expect(find.text('Treinador'), findsOneWidget);
    expect(find.text('Carlos'), findsOneWidget);

    await tester.tap(find.text('Dados do animal'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Microchip:'), findsNothing);
  });

  testWidgets(
    'treinador vê proprietário, atleta e outros treinadores nesta ordem',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: HorseProfileScreen(
            horseId: 'horse-1',
            currentUserId: 'trainer-current',
            repository: _FakeRepository(
              _horse(
                athlete: const HorseProfilePerson(
                  id: 'athlete-1',
                  name: 'Beatriz',
                ),
                trainers: const [
                  HorseProfilePerson(
                    id: 'trainer-current',
                    name: 'Treinador atual',
                  ),
                  HorseProfilePerson(id: 'trainer-other', name: 'Carlos'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treinador atual'), findsNothing);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('Beatriz'), findsOneWidget);
      expect(find.text('Carlos'), findsOneWidget);

      final ownerLeft = tester.getTopLeft(find.text('Proprietário')).dx;
      final athleteLeft = tester.getTopLeft(find.text('Atleta')).dx;
      final trainerLeft = tester.getTopLeft(find.text('Treinador')).dx;
      expect(ownerLeft, lessThan(athleteLeft));
      expect(athleteLeft, lessThan(trainerLeft));
    },
  );

  testWidgets('proprietário e atleta não veem o próprio vínculo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(
          horseId: 'horse-1',
          currentUserId: 'owner-1',
          repository: _FakeRepository(
            _horse(
              responsibilities: const ['PROPRIETARIO', 'ATLETA'],
              athlete: const HorseProfilePerson(id: 'owner-1', name: 'Ana'),
              trainers: const [
                HorseProfilePerson(id: 'trainer-1', name: 'Carlos'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsNothing);
    expect(find.text('Carlos'), findsOneWidget);
  });

  testWidgets('card da lesão ocupa toda a largura disponível da seção', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final injury = HorseInjuryRecord(
      date: DateTime(2026, 11, 14),
      description: 'Edema no boleto',
      prescription: 'Gelo e repouso',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(
          horseId: 'horse-1',
          repository: _FakeRepository(_horse(injuries: [injury])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final content = find.byKey(const Key('horse-injuries-content'));
    final card = find.byKey(
      ValueKey(
        'horse-injury-${injury.date.toIso8601String()}-'
        '${injury.description}',
      ),
    );
    final contentRect = tester.getRect(content);
    final cardRect = tester.getRect(card);

    expect(cardRect.left, contentRect.left);
    expect(cardRect.right, contentRect.right);
  });

  testWidgets('mostra o aviso antes de excluir o cavalo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(
          horseId: 'horse-1',
          repository: _FakeRepository(
            _horse(responsibilities: const ['PROPRIETARIO']),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final removeButton = find.byKey(const Key('remove-horse-button'));
    await tester.ensureVisible(removeButton);
    await tester.tap(removeButton);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('destructive-confirmation-dialog')),
      findsOneWidget,
    );
    expect(
      find.text('Tem certeza que quer excluir esse animal?'),
      findsOneWidget,
    );
    expect(find.textContaining('todos os dados relacionados'), findsOneWidget);
    expect(find.textContaining('usuários vinculados'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Sim'), findsOneWidget);
    expect(
      find.byKey(const Key('destructive-dialog-cancel-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('destructive-dialog-confirm-button')),
      findsOneWidget,
    );
  });

  testWidgets('confirma a exclusão chamando deleteHorse no repositório', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRepository(
      _horse(responsibilities: const ['PROPRIETARIO']),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(horseId: 'horse-1', repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final removeButton = find.byKey(const Key('remove-horse-button'));
    await tester.ensureVisible(removeButton);
    await tester.tap(removeButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('destructive-dialog-confirm-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.deletedHorseIds, ['horse-1']);
  });

  testWidgets('mostra progresso enquanto a exclusão está pendente', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final deletion = Completer<void>();
    final repository = _FakeRepository(
      _horse(responsibilities: const ['PROPRIETARIO']),
      deleteHorseOperation: (_) => deletion.future,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(horseId: 'horse-1', repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final removeButton = find.byKey(const Key('remove-horse-button'));
    await tester.ensureVisible(removeButton);
    await tester.tap(removeButton);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('destructive-dialog-confirm-button')),
    );
    await tester.pump();

    expect(find.byKey(const Key('delete-horse-progress')), findsOneWidget);
    expect(repository.deletedHorseIds, ['horse-1']);

    deletion.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('mantém Cavalos selecionado no menu inferior', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(
          horseId: 'horse-1',
          repository: _FakeRepository(_horse()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navigation = tester.widget<HomeBottomNavBar>(
      find.byType(HomeBottomNavBar),
    );
    expect(navigation.selectedDestination, HomeNavigationDestination.horses);
    expect(find.text('Cavalos'), findsOneWidget);
  });

  testWidgets('rola as fotos lateralmente e atualiza o índice inferior', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(
          horseId: 'horse-1',
          repository: _FakeRepository(
            _horse(
              images: const [
                HorseProfileImage(
                  path: '/horse-1.jpg',
                  url: 'https://example.test/horse-1.jpg',
                ),
                HorseProfileImage(
                  path: '/horse-2.jpg',
                  url: 'https://example.test/horse-2.jpg',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('horse-image-gallery')), findsOneWidget);
    expect(
      find.byKey(const Key('horse-gallery-page-indicator')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('horse-gallery-indicator-0-active')),
      findsOneWidget,
    );

    await tester.fling(
      find.byKey(const Key('horse-image-gallery')),
      const Offset(-500, 0),
      1000,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('horse-gallery-indicator-1-active')),
      findsOneWidget,
    );
  });

  testWidgets('abre a edição, bloqueia o microchip e salva por updateHorse', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRepository(
      _horse(responsibilities: const ['PROPRIETARIO']),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(horseId: 'horse-1', repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-horse-profile-button')));
    await tester.pumpAndSettle();

    expect(find.text('Editar cavalo'), findsOneWidget);
    final microchip = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('horse-edit-microchip-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(microchip.readOnly, isTrue);

    await tester.tap(find.byTooltip('Editar Nome'));
    await tester.enterText(
      find.byKey(const ValueKey('horse-edit-name-field')),
      'Trovão Atualizado',
    );
    final save = find.byKey(const Key('save-horse-profile-button'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(repository.lastUpdate?.name, 'Trovão Atualizado');
    expect(repository.lastUpdate?.toJson('horse-1'), isNot(contains('codigo')));
  });

  testWidgets('ao editar só o nome não reenvia limitação legada inválida', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRepository(
      _horse(
        responsibilities: const ['PROPRIETARIO'],
        physicalLimitations: List.generate(31, (index) => 'Limitação $index'),
      ),
      rejectInvalidLegacyLimitations: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(horseId: 'horse-1', repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-horse-profile-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar Nome'));
    await tester.enterText(
      find.byKey(const ValueKey('horse-edit-name-field')),
      'Trovão Atualizado',
    );
    final save = find.byKey(const Key('save-horse-profile-button'));
    for (var attempt = 0; save.evaluate().isEmpty && attempt < 10; attempt++) {
      await tester.fling(
        find.byType(ListView).last,
        const Offset(0, -700),
        1200,
      );
      await tester.pumpAndSettle();
    }
    expect(save, findsOneWidget);
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('Dados do cavalo atualizados.'), findsOneWidget);
    expect(find.textContaining('limitações físicas'), findsNothing);
    expect(repository.lastUpdate?.toJson('horse-1'), {
      'id': 'horse-1',
      'nome': 'Trovão Atualizado',
    });
  });

  testWidgets('edição reutiliza o modal de inclusão do perfil', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRepository(
      _horse(responsibilities: const ['PROPRIETARIO']),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileScreen(horseId: 'horse-1', repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit-horse-profile-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('add-horse-edit-image-button')),
      findsOneWidget,
    );
    final addLimitation = find.byKey(
      const Key('add-horse-edit-limitation-button'),
    );
    await tester.ensureVisible(addLimitation);
    await tester.tap(addLimitation);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('horse-text-entry-dialog')), findsOneWidget);
    expect(find.text('Adicionar limitação'), findsOneWidget);
  });

  testWidgets('Imagens + Adicionar pede permissão e abre a galeria', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final events = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: HorseProfileEditScreen(
          horse: _horse(responsibilities: const ['PROPRIETARIO']),
          repository: _FakeRepository(
            _horse(responsibilities: const ['PROPRIETARIO']),
          ),
          imageSelectionService: HorseImageSelectionService(
            requestPermission: () async {
              events.add('permissão');
              return HorseImageLibraryAccess.granted;
            },
            pickImages: () async {
              events.add('galeria');
              return [];
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addImage = find.byKey(const Key('add-horse-edit-image-button'));
    await tester.ensureVisible(addImage);
    await tester.tap(addImage);
    await tester.pumpAndSettle();

    expect(events, ['permissão', 'galeria']);
  });
}

class _FakeRepository implements HorseProfileRepository {
  _FakeRepository(
    this.horse, {
    this.rejectInvalidLegacyLimitations = false,
    this.deleteHorseOperation,
  });
  final HorseProfileData horse;
  final bool rejectInvalidLegacyLimitations;
  final Future<void> Function(String id)? deleteHorseOperation;
  HorseProfileUpdate? lastUpdate;
  int relationshipUpdateCalls = 0;
  bool? lastRemoveAthlete;
  bool? lastRemoveTrainer;
  String? lastAthleteEmail;
  String? lastTrainerEmail;
  final List<String> deletedHorseIds = [];

  @override
  Future<HorseProfileData> getHorse(String id) async => horse;

  @override
  Future<List<HorseProfileModality>> getModalities() async => const [];

  @override
  Future<void> deleteHorse(String id) async {
    deletedHorseIds.add(id);
    await deleteHorseOperation?.call(id);
  }

  @override
  Future<HorseProfileData> updateHorse(
    String id,
    HorseProfileUpdate update,
  ) async {
    lastUpdate = update;
    if (rejectInvalidLegacyLimitations &&
        (update.physicalLimitations?.added.length ?? 0) > 30) {
      throw FirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'Limitações físicas: informe no máximo 30 itens.',
      );
    }
    return horse;
  }

  @override
  Future<HorseProfileData> updateRelationships(
    String id, {
    required bool removeAthlete,
    required bool removeTrainer,
    String? athleteEmail,
    String? trainerEmail,
  }) async {
    relationshipUpdateCalls++;
    lastRemoveAthlete = removeAthlete;
    lastRemoveTrainer = removeTrainer;
    lastAthleteEmail = athleteEmail;
    lastTrainerEmail = trainerEmail;
    return horse;
  }

  @override
  Future<HorseProfileImageUploadResult> addHorseImages(
    String id, {
    required List<HorseProfileImageUpload> images,
  }) async => HorseProfileImageUploadResult(
    horse: horse,
    uploaded: images.length,
    failed: 0,
  );

  @override
  Future<HorseProfileData> removeHorseImage(String id, String path) async =>
      horse;
}

HorseProfileData _horse({
  List<String> responsibilities = const [],
  HorseProfilePerson? athlete,
  List<HorseProfilePerson> trainers = const [],
  List<HorseProfileImage> images = const [],
  List<String> physicalLimitations = const [],
  List<HorseInjuryRecord> injuries = const [],
  HorseProfilePlan? currentPlan,
  HorseProfileTrainingAction trainingAction = HorseProfileTrainingAction.none,
}) => HorseProfileData(
  id: 'horse-1',
  microchip: '123123456789012',
  name: 'Trovão',
  birthDate: DateTime(2016, 4, 10),
  age: const HorseProfileAge(years: 10, months: 7),
  breed: 'BH',
  coat: 'Tordilho',
  sex: 'MACHO',
  images: images,
  modality: null,
  physicalLimitations: physicalLimitations,
  healthNotes: const [],
  injuries: injuries,
  owner: const HorseProfilePerson(id: 'owner-1', name: 'Ana'),
  athlete: athlete,
  trainers: trainers,
  currentPlan: currentPlan,
  evaluations: const [],
  responsibilities: responsibilities,
  trainingAction: trainingAction,
);

// Carrega uma execução mínima sem acessar as três callables de produção.
class _FakeTodayTrainingLoader implements TrainingExecutionLoader {
  const _FakeTodayTrainingLoader();

  @override
  Future<TrainingExecutionData> fetchTraining(
    TrainingExecutionReference reference,
  ) async => TrainingExecutionData(
    recordId: reference.recordId,
    title: reference.title,
    durationMinutes: reference.durationMinutes,
    description: 'Treino carregado diretamente pelo perfil.',
    guidelines: const [],
    exercises: const [],
    isFinished: false,
    canStart: true,
  );
}

// Satisfaz a dependência da execução ativa sem enviar registros ao Firebase.
class _FakeTrainingSubmitter implements TrainingCompletionSubmitter {
  const _FakeTrainingSubmitter();

  @override
  Future<TrainingCompletionResult> submit(
    TrainingCompletionInput input,
  ) async => const TrainingCompletionResult(status: 'REALIZADO');
}
