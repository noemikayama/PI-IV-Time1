import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/guardian_home_data.dart';
import '../../data/services/mock_guardian_home_service.dart';
import 'daily_training_card.dart';
import 'training_stats_card.dart';
import 'guardian_list_card.dart';

// Mantém a tela separada da fonte dos dados. Não necessita de Firebase.
class GuardianHomeContent extends StatefulWidget {
  const GuardianHomeContent({super.key, this.homeFuture});

  final Future<GuardianHomeData>? homeFuture;

  @override
  State<GuardianHomeContent> createState() => _GuardianHomeContentState();
}

class _GuardianHomeContentState extends State<GuardianHomeContent> {
  final _service = const MockGuardianHomeService();
  late Future<GuardianHomeData> _homeFuture;

  @override
  void initState() {
    super.initState();
    _homeFuture = widget.homeFuture ?? _service.fetchHome();
  }

  void _load() {
    _homeFuture = _service.fetchHome();
  }

  @override
  void didUpdateWidget(covariant GuardianHomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.homeFuture != null && widget.homeFuture != oldWidget.homeFuture) {
      _homeFuture = widget.homeFuture!;
    }
  }

  void _retry() {
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GuardianHomeData>(
      future: _homeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Não foi possível carregar os dados da Home.'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _retry, child: const Text('Tentar novamente')),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final theme = Theme.of(context);
        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 380;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Olá ${data.guardianName}!',
                        style: theme.textTheme.displaySmall?.copyWith(color: AppColors.prussianBlue)),
                      Text('Qual será a aventura de hoje?', style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 32),
                      DailyTrainingCard(trainings: data.todayTrainings),
                      const SizedBox(height: 24),
                      if (isNarrow) ...[
                        TrainingStatsCard(
                          title: 'Treinos realizados nesta semana',
                          completed: data.weeklyCompleted,
                          total: data.weeklyPlanned,
                          gradientColors: const [AppColors.seaGreen, AppColors.pearlAqua],
                        ),
                        const SizedBox(height: 16),
                        TrainingStatsCard(
                          title: 'Treinos realizados este mês',
                          completed: data.monthlyCompleted,
                          total: data.monthlyPlanned,
                          gradientColors: const [AppColors.goldenApricot, Color(0xFFE7BB87)],
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: TrainingStatsCard(
                              title: 'Treinos realizados nesta semana',
                              completed: data.weeklyCompleted,
                              total: data.weeklyPlanned,
                              gradientColors: const [AppColors.seaGreen, AppColors.pearlAqua],
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: TrainingStatsCard(
                              title: 'Treinos realizados este mês',
                              completed: data.monthlyCompleted,
                              total: data.monthlyPlanned,
                              gradientColors: const [AppColors.goldenApricot, Color(0xFFE7BB87)],
                            )),
                          ],
                        ),
                      const SizedBox(height: 24),
                      TrainingStatsCard(
                        title: 'Treinos realizados desde sempre',
                        completed: data.allTimeCompleted,
                        gradientColors: const [AppColors.tropicalTeal, AppColors.prussianBlue],
                      ),
                      const SizedBox(height: 24),
                      GuardianListCard(
                        title: 'Meus cavalos',
                        icon: Icons.pets,
                        useHorseAsset: true,
                        maxVisibleItems: 2,
                        showArrow: true,
                        items: data.horses,
                      ),
                      const SizedBox(height: 24),
                      GuardianListCard(
                        title: 'Meus treinadores',
                        icon: Icons.person_outline,
                        items: data.trainers,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
