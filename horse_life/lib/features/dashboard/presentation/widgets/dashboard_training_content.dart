// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO DE ALTERAÇÕES
// 30/10/2026 - Extração do painel de treinos compartilhado entre Guardian e Trainer.
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../data/dashboard_mock_data.dart';
import 'dashboard_filters.dart';
import 'dashboard_metric_card.dart';
import 'dashboard_training_card.dart';
import 'dashboard_recent_list.dart';
import 'dashboard_empty_state.dart';

class DashboardTrainingContent extends StatefulWidget {
  const DashboardTrainingContent({super.key, this.empty = false});
  final bool empty;

  @override
  State<DashboardTrainingContent> createState() =>
      _DashboardTrainingContentState();
}

class _DashboardTrainingContentState extends State<DashboardTrainingContent> {
  String _horseId = 'Todos';
  String _period = 'Desde sempre';

  @override
  Widget build(BuildContext context) {
    final snapshot = DashboardMockData.snapshot(
      horseId: _horseId,
      period: _period,
    );
    final stats = snapshot.statistics;
    final horses = <String>[
      'Todos',
      ...DashboardMockData.horses.map((e) => e.name),
    ];
    final selectedHorse = _horseId == 'Todos'
        ? 'Todos'
        : DashboardMockData.horseName(_horseId);
    final empty = widget.empty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardFilters(
          horse: selectedHorse,
          period: _period,
          horses: horses,
          periods: DashboardMockData.periods,
          onHorseChanged: (value) => setState(() {
            _horseId = value == 'Todos'
                ? value
                : DashboardMockData.horses
                      .firstWhere((e) => e.name == value)
                      .id;
          }),
          onPeriodChanged: (value) => setState(() => _period = value),
        ),
        const SizedBox(height: 22),
        if (empty || stats.total == 0) ...[
          const DashboardEmptyState(),
        ] else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 18.0;
              final width = (constraints.maxWidth - gap) / 2;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: width,
                    height: 478,
                    child: DashboardTrainingCard(
                      completedPercent: stats.completedPercent,
                      partialPercent: stats.partialPercent,
                      total: stats.total,
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      children: [
                        DashboardMetricCard(
                          title: 'Percentual de cumprimento dos treinos',
                          value: '${stats.compliancePercent.round()}%',
                          gradient: const [
                            AppColors.goldenApricot,
                            Color(0xFFFFC488),
                          ],
                        ),
                        const SizedBox(height: 18),
                        DashboardMetricCard(
                          title: 'Frequência de execução dos treinos',
                          value: '${stats.frequencyPercent.round()}%',
                          gradient: const [
                            AppColors.tropicalTeal,
                            AppColors.prussianBlue,
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          DashboardRecentList(
            title: 'Últimos treinos',
            trainings: snapshot.trainings,
          ),
          const SizedBox(height: 22),
          DashboardRecentList(
            title: 'Últimos Feedbacks',
            trainings: snapshot.trainings,
            feedbacks: snapshot.feedbacks,
            feedback: true,
          ),
        ],
      ],
    );
  }
}
