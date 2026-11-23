// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes do padrão visual, conteúdo, rolagem horizontal
// e seleção individual dos treinos recentes do dashboard.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/dashboard/presentation/widgets/dashboard_recent_list.dart';
import 'package:horse_life/features/home/presentation/widgets/home_section_card.dart';
import 'package:horse_life/features/home/presentation/widgets/horse_asset_icon.dart';

void main() {
  const trainings = <Map<String, dynamic>>[
    {
      'registroId': 'record-1',
      'nomeTreino': 'Treino de equilíbrio',
      'nomeCavalo': 'Apollo',
      'nomePlano': 'Plano semanal',
      'data': '2026-11-23',
    },
    {
      'registroId': 'record-2',
      'nomeTreino': 'Treino de resistência',
      'nomeCavalo': 'Luna',
      'nomePlano': 'Plano mensal',
      'data': '2026-11-22',
    },
  ];

  testWidgets('uses the home section pattern and horizontal training list', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: DashboardRecentList(
              title: 'Últimos treinos',
              liveTrainings: trainings,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(HomeSectionCard), findsOneWidget);
    expect(find.byType(HorseAssetIcon), findsWidgets);
    expect(find.text('Apollo'), findsOneWidget);
    expect(find.text('23/11/2026'), findsOneWidget);

    final section = tester.widget<HomeSectionCard>(
      find.byType(HomeSectionCard),
    );
    expect(section.padding, const EdgeInsets.all(18));

    final list = tester.widget<ListView>(
      find.byKey(const Key('dashboard-recent-training-list')),
    );
    expect(list.scrollDirection, Axis.horizontal);
  });

  testWidgets('returns the selected training from the view button', (
    tester,
  ) async {
    Map<String, dynamic>? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: DashboardRecentList(
              title: 'Últimos treinos',
              liveTrainings: trainings,
              onItemTap: (training) => selected = training,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ver treino').first);
    await tester.pump();

    expect(selected?['registroId'], 'record-1');
  });

  testWidgets('single training fills the carousel width evenly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: DashboardRecentList(
              title: 'Últimos treinos',
              liveTrainings: [trainings.first],
            ),
          ),
        ),
      ),
    );

    final listWidth = tester
        .getSize(find.byKey(const Key('dashboard-recent-training-list')))
        .width;
    final itemWidth = tester
        .getSize(find.byKey(const Key('dashboard-recent-training-item-0')))
        .width;

    expect(itemWidth, listWidth);
  });
}
