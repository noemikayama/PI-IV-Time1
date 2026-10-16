import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/guardian_home_data.dart';
import 'guardian_section_card.dart';
import 'horse_asset_icon.dart';
import 'guardian_empty_state.dart';

/// Exibe até um treino por vez; com dois ou mais, permite rolagem vertical.
class DailyTrainingCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final pending = trainings.where((t) => !t.isCompleted).toList();
    final allCompleted = trainings.isNotEmpty && pending.isEmpty;
    return GuardianSectionCard(
      title: 'Treinos do dia',
      onShowAll: onShowAll,
      child: pending.isEmpty
          ? GuardianEmptyState(
              icon: allCompleted
                  ? Icons.event_available_outlined
                  : Icons.event_busy_outlined,
              title: allCompleted ? 'Todos concluídos' : 'Nenhum treino marcado',
              description: allCompleted
                  ? 'Continue assim! Consistência e dedicação são o caminho para o sucesso.'
                  : 'Aproveite o dia para descansar e se preparar para os próximos exercícios',
            )
          : pending.length == 1
              ? _TrainingDetails(training: pending.first, position: 1, count: 1, onStart: onStart)
              : SizedBox(
                  height: 284,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      primary: false,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(right: 10),
                      itemCount: pending.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _TrainingDetails(
                        training: pending[index],
                        position: index + 1,
                        count: pending.length,
                        onStart: onStart,
                      ),
                    ),
                  ),
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
          Row(children: [
            Expanded(child: Text(training.title,
              style: theme.textTheme.titleLarge?.copyWith(color: AppColors.text))),
            const SizedBox(width: 8),
            Text('$position/$count', style: theme.textTheme.bodyMedium),
          ]),
          const SizedBox(height: 14),
          _Info(icon: const HorseAssetIcon(), text: training.horseName),
          _Info(icon: const Icon(Icons.person_outline), text: training.trainerName),
          _Info(icon: const Icon(Icons.timer_outlined), text: '${training.durationMinutes} minutos'),
          _Info(icon: const Icon(Icons.assignment_outlined), text: training.planName),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    child: Row(children: [
      SizedBox(width: 28, height: 28, child: Center(child: IconTheme(
        data: const IconThemeData(color: AppColors.prussianBlue, size: 26),
        child: icon,
      ))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium)),
    ]),
  );
}
