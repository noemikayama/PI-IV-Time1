// RESPONSÁVEL PELA ATUALIZAÇÃO: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Definição da rolagem lateral definitiva com PageView e indicadores interativos; preservados os estados vazios e a integração com os dados simulados.
// -----------------------------------------------------------------------------
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../data/models/guardian_home_data.dart';
import 'guardian_section_card.dart';
import 'horse_asset_icon.dart';
import 'guardian_empty_state.dart';

/// Exibe treinos pendentes em carrossel horizontal com indicadores de página.
/// Apresenta treinos pendentes em carrossel horizontal com indicadores de página.
class DailyTrainingCard extends StatefulWidget {
  final List<GuardianTraining> trainings;
  final void Function(GuardianTraining training)? onStart;
  final VoidCallback? onShowAll;

  const DailyTrainingCard({
    super.key,
    required this.trainings,
    this.onStart,
    this.onShowAll,
  });

  @override
  State<DailyTrainingCard> createState() => _DailyTrainingCardState();
}

class _DailyTrainingCardState extends State<DailyTrainingCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant DailyTrainingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinicia a página ao receber uma nova lista de treinos.
    if (!identical(widget.trainings, oldWidget.trainings)) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.trainings.where((t) => !t.isCompleted).toList();
    final allCompleted = widget.trainings.isNotEmpty && pending.isEmpty;
    return GuardianSectionCard(
      title: 'Treinos do dia',
      onShowAll: widget.onShowAll,
      child: pending.isEmpty
          ? GuardianEmptyState(
              icon: allCompleted
                  ? Icons.event_available_outlined
                  : Icons.event_busy_outlined,
              title: allCompleted
                  ? 'Todos concluídos'
                  : 'Nenhum treino marcado',
              description: allCompleted
                  ? 'Continue assim! Consistência e dedicação são o caminho para o sucesso.'
                  : 'Aproveite o dia para descansar e se preparar para os próximos exercícios',
            )
          : pending.length == 1
          ? _TrainingDetails(
              training: pending.first,
              position: 1,
              count: 1,
              onStart: widget.onStart,
            )
          : Column(
              children: [
                SizedBox(
                  height: 320,
                  // Uma página por treino pendente; a mudança de página atualiza as bolinhas.
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pending.length,
                    onPageChanged: (index) {
                      // Mantém o indicador visual sincronizado com o gesto lateral.
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) => _TrainingDetails(
                      training: pending[index],
                      position: index + 1,
                      count: pending.length,
                      onStart: widget.onStart,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Semantics(
                  label: 'Treino ${_currentPage + 1} de ${pending.length}',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pending.length, (index) {
                      final selected = index == _currentPage;
                      return Tooltip(
                        message: 'Ir para o treino ${index + 1}',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: selected ? 24 : 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : Colors.white54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TrainingDetails extends StatelessWidget {
  final GuardianTraining training;
  final int position;
  final int count;
  final void Function(GuardianTraining training)? onStart;

  const _TrainingDetails({
    required this.training,
    required this.position,
    required this.count,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  training.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$position/$count', style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 14),
          _Info(icon: const HorseAssetIcon(), text: training.horseName),
          _Info(
            icon: const Icon(Icons.sports),
            text: training.trainerName,
          ),
          _Info(
            icon: const Icon(Icons.timer_outlined),
            text: '${training.durationMinutes} minutos',
          ),
          _Info(
            icon: const Icon(Icons.assignment_outlined),
            text: training.planName,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onStart == null ? null : () => onStart!(training),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Iniciar treino'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.seaGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.alabasterGray,
                disabledForegroundColor: AppColors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final Widget icon;
  final String text;
  const _Info({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: IconTheme(
              data: const IconThemeData(
                color: AppColors.prussianBlue,
                size: 26,
              ),
              child: icon,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    ),
  );
}
