// RESPONSÁVEL PELA ATUALIZAÇÃO: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos segmentos de carregamento, erro, estado vazio e
// composição dos cards da Home do responsável.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Ação de toque nos cavalos persistidos da Home.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Exibe cavalos de demonstração somente durante a sessão atual,
// sem depender de novo carregamento da Home após o cadastro mockado.
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão e padronização dos componentes e dados simulados da Home
// do Responsável, preservando a integração existente.
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../data/models/guardian_home_data.dart';
import 'daily_training_card.dart';
import 'training_stats_card.dart';
import 'guardian_list_card.dart';

// Mantém a tela separada da fonte dos dados. Não necessita de Firebase.
/// Organiza os cards consumindo a Future injetada pela Screen, sem acessar Firebase diretamente.
class GuardianHomeContent extends StatefulWidget {
  const GuardianHomeContent({
    super.key,
    required this.homeFuture,
    required this.onRetry,
    this.onRegisterHorse,
    this.sessionMockHorses = const [],
    this.onSelectHorse,
  });

  final Future<GuardianHomeData> homeFuture;
  final VoidCallback onRetry;
  final VoidCallback? onRegisterHorse;
  final List<String> sessionMockHorses;
  final ValueChanged<String>? onSelectHorse;

  @override
  State<GuardianHomeContent> createState() => _GuardianHomeContentState();
}

class _GuardianHomeContentState extends State<GuardianHomeContent> {
  @override
  Widget build(BuildContext context) {
    // A mesma Future atende loading, erro e sucesso; tentar novamente é delegado à Screen.
    return FutureBuilder<GuardianHomeData>(
      future: widget.homeFuture,
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
                  FilledButton(
                    onPressed: widget.onRetry,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('Nenhum dado disponível.'));
        }
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
                      Text(
                        'Olá ${data.guardianName}!',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: AppColors.prussianBlue,
                        ),
                      ),
                      Text(
                        'Qual será a aventura de hoje?',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      DailyTrainingCard(trainings: data.todayTrainings),
                      const SizedBox(height: 24),
                      if (isNarrow) ...[
                        TrainingStatsCard(
                          title: 'Treinos realizados nesta semana',
                          completed: data.weeklyCompleted,
                          total: data.weeklyPlanned,
                          gradientColors: const [
                            AppColors.seaGreen,
                            AppColors.pearlAqua,
                          ],
                        ),
                        const SizedBox(height: 16),
                        TrainingStatsCard(
                          title: 'Treinos realizados este mês',
                          completed: data.monthlyCompleted,
                          total: data.monthlyPlanned,
                          gradientColors: const [
                            AppColors.goldenApricot,
                            Color(0xFFE7BB87),
                          ],
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TrainingStatsCard(
                                title: 'Treinos realizados nesta semana',
                                completed: data.weeklyCompleted,
                                total: data.weeklyPlanned,
                                gradientColors: const [
                                  AppColors.seaGreen,
                                  AppColors.pearlAqua,
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TrainingStatsCard(
                                title: 'Treinos realizados este mês',
                                completed: data.monthlyCompleted,
                                total: data.monthlyPlanned,
                                gradientColors: const [
                                  AppColors.goldenApricot,
                                  Color(0xFFE7BB87),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      TrainingStatsCard(
                        title: 'Treinos realizados desde sempre',
                        completed: data.allTimeCompleted,
                        gradientColors: const [
                          AppColors.tropicalTeal,
                          AppColors.prussianBlue,
                        ],
                      ),
                      const SizedBox(height: 24),
                      GuardianListCard(
                        title: 'Meus cavalos',
                        icon: Icons.pets,
                        useHorseAsset: true,
                        maxVisibleItems: 2,
                        showArrow: true,
                        items: [...data.horses, ...widget.sessionMockHorses],
                        onItemTap: widget.onSelectHorse == null
                            ? null
                            : (index) {
                                if (index < data.horseIds.length) {
                                  widget.onSelectHorse!(data.horseIds[index]);
                                }
                              },
                        onRegisterHorse:
                            widget.onRegisterHorse ??
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'A tela de cadastro de cavalos será adicionada futuramente.',
                                  ),
                                ),
                              );
                            },
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
