// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Filtragem defensiva de treinos CANCELADO no carrossel de treinos do dia.
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Criação do carrossel horizontal dos treinos do Profissional,
// incluindo indicador de posição, ação de visualizar e estado vazio.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão de integração e compatibilidade com a arquitetura
// Repository/Mapper/Service, sem alterar a composição visual aprovada.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../data/models/trainer_home_data.dart';
import 'home_empty_state.dart';
import 'home_section_card.dart';
import 'horse_asset_icon.dart';

class TrainerDailyTrainingCard extends StatefulWidget {
  const TrainerDailyTrainingCard({
    super.key,
    required this.trainings,
    this.onViewTraining,
    this.onShowAll,
  });

  final List<TrainerTraining> trainings;
  final ValueChanged<TrainerTraining>? onViewTraining;
  final VoidCallback? onShowAll;

  @override
  State<TrainerDailyTrainingCard> createState() =>
      _TrainerDailyTrainingCardState();
}

class _TrainerDailyTrainingCardState
    extends State<TrainerDailyTrainingCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant TrainerDailyTrainingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.trainings, widget.trainings)) {
      _currentPage = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trainings = widget.trainings
        .where((t) => t.status != 'CANCELADO')
        .toList(growable: false);

    return HomeSectionCard(
      title: 'Treinos do dia',
      onShowAll: widget.onShowAll,
      child: trainings.isEmpty
          ? const HomeEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Nenhum treino marcado',
              description: 'Aproveite o dia para responder feedbacks ou montar novos treinos',
            )
          : Column(
              children: [
                SizedBox(
                  height: 188,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: trainings.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) => _TrainerTrainingPreview(
                      training: trainings[index],
                      index: index + 1,
                      count: trainings.length,
                      onViewTraining: widget.onViewTraining,
                    ),
                  ),
                ),
                if (trainings.length > 1) ...[
                  const SizedBox(height: 10),
                  Semantics(
                    label: 'Treino ${_currentPage + 1} de ${trainings.length}',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(trainings.length, (index) {
                        final selected = index == _currentPage;
                        return Tooltip(
                          message: 'Ver treino ${index + 1}',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 5,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                height: 8,
                                width: selected ? 22 : 8,
                                decoration: BoxDecoration(
                                  color: selected ? Colors.white : Colors.white54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _TrainerTrainingPreview extends StatelessWidget {
  const _TrainerTrainingPreview({
    required this.training,
    required this.index,
    required this.count,
    this.onViewTraining,
  });

  final TrainerTraining training;
  final int index;
  final int count;
  final ValueChanged<TrainerTraining>? onViewTraining;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  training.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('$index/$count', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 7),
          _TrainingInfo(
            icon: const HorseAssetIcon(size: 21),
            text: training.horseName,
          ),
          _TrainingInfo(
            icon: const Icon(Icons.assignment_outlined, size: 21),
            text: training.planName,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 39,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.seaGreen, AppColors.blueSpruce],
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: onViewTraining == null
                      ? null
                      : () => onViewTraining!(training),
                  child: Center(
                    child: Text(
                      'Ver treino ↗',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingInfo extends StatelessWidget {
  const _TrainingInfo({required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(width: 24, height: 24, child: Center(child: icon)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
