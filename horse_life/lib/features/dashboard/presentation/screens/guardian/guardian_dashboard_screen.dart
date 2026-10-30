// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO DE ALTERAÇÕES
// 29/10/2026 - Dashboard Guardian modular.
// 29/10/2026 - Mock relacional, filtros por cavalo/período e listas horizontais.
// 30/10/2026 - Ajustes de proporções, espaçamento e alinhamento ao Figma.
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/core/widgets/guardian_sidebar.dart';
import '../../../data/dashboard_mock_data.dart';
import '../../widgets/dashboard_filters.dart';
import '../../widgets/dashboard_metric_card.dart';
import '../../widgets/dashboard_training_card.dart';
import '../../widgets/dashboard_recent_list.dart';
import '../../widgets/dashboard_empty_state.dart';
import '../../widgets/dashboard_text_styles.dart';

/// O treinador poderá reutilizar o mesmo conteúdo de treinos em seu dashboard.
class GuardianDashboardScreen extends StatefulWidget {
  const GuardianDashboardScreen({
    super.key,
    required this.onLogout,
    this.onHome,
    this.empty = false,
  });
  final Future<void> Function() onLogout;
  final VoidCallback? onHome;
  final bool empty;

  @override
  State<GuardianDashboardScreen> createState() =>
      _GuardianDashboardScreenState();
}

class _GuardianDashboardScreenState extends State<GuardianDashboardScreen> {
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const HomeAppBar(),
      drawer: GuardianSidebar(onLogout: widget.onLogout),
      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: 3,
        onItemSelected: (index) {
          if (index == 0) {
            if (widget.onHome != null) {
              widget.onHome!();
            } else {
              Navigator.of(context).maybePop();
            }
          }
        },
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text(
                'Evolução',
                textAlign: TextAlign.center,
                style: DashboardTextStyles.pageTitle(context),
              ),
              const SizedBox(height: 24),
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
              if (widget.empty || stats.total == 0) ...[
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
          ),
        ),
      ),
    );
  }
}
