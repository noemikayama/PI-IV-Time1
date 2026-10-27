// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Composição da Home do Profissional conforme protótipos normal e
// vazio, com carregamento, erro, quatro métricas, treinos e vínculos.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão de integração e compatibilidade com a arquitetura
// Repository/Mapper/Service, sem alterar a composição visual aprovada.
// -----------------------------------------------------------------------------

import 'dart:math' as math;
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Indicador de exercícios renomeado de acordo com o cálculo
// realizado pela Cloud Function (exercícios ativos do treinador).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../data/models/professional_home_data.dart';
import 'professional_daily_training_card.dart';
import 'professional_list_card.dart';
import 'professional_stats_card.dart';

class ProfessionalHomeContent extends StatelessWidget {
  const ProfessionalHomeContent({
    super.key,
    required this.homeFuture,
    required this.onRetry,
    this.onViewTraining,
    this.onSelectHorse,
    this.onSelectClient,
    this.onShowAllTrainings,
    this.onShowAllHorses,
    this.onShowAllClients,
  });

  final Future<ProfessionalHomeData> homeFuture;
  final VoidCallback onRetry;
  final ValueChanged<ProfessionalTraining>? onViewTraining;
  final ValueChanged<ProfessionalHorse>? onSelectHorse;
  final ValueChanged<ProfessionalClient>? onSelectClient;
  final VoidCallback? onShowAllTrainings;
  final VoidCallback? onShowAllHorses;
  final VoidCallback? onShowAllClients;

  /// Prévia local: o app pode substituir esta ação por uma rota real.
  void _viewTraining(BuildContext context, ProfessionalTraining training) {
    if (onViewTraining != null) {
      onViewTraining!(training);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(training.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              Text('Cavalo: ${training.horseName}'),
              const SizedBox(height: 8),
              Text('Plano: ${training.planName}'),
            ],
          ),
        ),
      ),
    );
  }

  /// Exibe todos os registros sem depender das rotas ainda não implementadas.
  void _showAll<T>(
    BuildContext context, {
    required String title,
    required List<T> items,
    required String Function(T) label,
    ValueChanged<T>? onTap,
  }) {
    final sheetHeight = math.min(
      MediaQuery.sizeOf(context).height * 0.70,
      105.0 + items.length * 62.0,
    );

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: math.max(190.0, sheetHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 12),
                Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('Nenhum item disponível.'))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) => ListTile(
                            title: Text(label(items[index])),
                            trailing: onTap == null
                                ? null
                                : const Icon(Icons.chevron_right_rounded),
                            onTap: onTap == null
                                ? null
                                : () {
                                    Navigator.of(sheetContext).pop();
                                    onTap(items[index]);
                                  },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProfessionalHomeData>(
      future: homeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Não foi possível carregar os dados da Home.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onRetry,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final theme = Theme.of(context);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá ${data.professionalName}!',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: AppColors.prussianBlue,
                    ),
                  ),
                  Text(
                    'Qual será a aventura de hoje?',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  ProfessionalDailyTrainingCard(
                    trainings: data.todayTrainings,
                    onViewTraining: (training) =>
                        _viewTraining(context, training),
                    onShowAll: onShowAllTrainings ??
                        () => _showAll<ProfessionalTraining>(
                              context,
                              title: 'Treinos do dia',
                              items: data.todayTrainings,
                              label: (training) =>
                                  '${training.title} — ${training.horseName}',
                              onTap: (training) => _viewTraining(context, training),
                            ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ProfessionalStatsCard(
                          title: 'Feedbacks feitos nesta semana',
                          value: data.weeklyFeedbacksDone,
                          total: data.weeklyFeedbacksTotal,
                          gradientColors: const [
                            AppColors.seaGreen,
                            AppColors.pearlAqua,
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ProfessionalStatsCard(
                          title: 'Total de planos ativos',
                          value: data.activePlans,
                          gradientColors: const [
                            AppColors.goldenApricot,
                            Color(0xFFFFC78D),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ProfessionalStatsCard(
                          title: 'Treinos realizados nesta semana',
                          value: data.weeklyTrainingsCompleted,
                          total: data.weeklyTrainingsPlanned,
                          gradientColors: const [
                            AppColors.prussianBlue,
                            AppColors.tropicalTeal,
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ProfessionalStatsCard(
                          title: 'Exercícios ativos',
                          value: data.createdExercises,
                          gradientColors: const [
                            Color(0xFFC8A1BC),
                            AppColors.tropicalTeal,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ProfessionalListCard<ProfessionalHorse>(
                    title: 'Meus cavalos',
                    items: data.horses,
                    itemName: (horse) => horse.name,
                    isHorseList: true,
                    emptyTitle: 'Nenhum animal vinculado',
                    emptyDescription:
                        'Prescreva treinos para os cavalos vinculados a você.',
                    onItemTap: onSelectHorse,
                    onShowAll: onShowAllHorses ??
                        () => _showAll<ProfessionalHorse>(
                              context,
                              title: 'Meus cavalos',
                              items: data.horses,
                              label: (horse) => horse.name,
                              onTap: onSelectHorse,
                            ),
                  ),
                  const SizedBox(height: 16),
                  ProfessionalListCard<ProfessionalClient>(
                    title: 'Meus clientes',
                    items: data.clients,
                    itemName: (client) => client.name,
                    emptyTitle: 'Nenhum cliente vinculado',
                    emptyDescription:
                        'Ao vincular-se a um cavalo, você automaticamente se vincula ao seu responsável.',
                    onItemTap: onSelectClient,
                    onShowAll: onShowAllClients ??
                        () => _showAll<ProfessionalClient>(
                              context,
                              title: 'Meus clientes',
                              items: data.clients,
                              label: (client) => client.name,
                              onTap: onSelectClient,
                            ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
