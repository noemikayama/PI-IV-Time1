// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos cards de seção por dia da semana, card de treinamento
// selecionado e card selecionável da galeria para o cadastro de planos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';

import '../../data/models/training_plan_gallery_item.dart';
import '../../data/models/training_plan_weekday.dart';

/// Card de agrupamento semanal exibido nas etapas de seleção e revisão de
/// treinamentos do plano.
class TrainingPlanWeekdaySectionCard extends StatelessWidget {
  const TrainingPlanWeekdaySectionCard({
    required this.weekday,
    this.training,
    this.onAddFromGallery,
    this.onCreateTraining,
    this.onRemoveTraining,
    super.key,
  });

  final TrainingPlanWeekday weekday;
  final TrainingPlanGalleryItem? training;
  final VoidCallback? onAddFromGallery;
  final VoidCallback? onCreateTraining;
  final VoidCallback? onRemoveTraining;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: const BoxDecoration(
        color: Color(0xFFDEDEDE),
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            weekday.label,
            style: textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          if (training == null) ...[
            const SizedBox(height: 14),
            AppAddItemButton(
              buttonKey: Key('add-gallery-training-${weekday.name}'),
              label: 'Adicionar da galeria',
              height: 54,
              backgroundColor: const Color(0xFFEBEBEB),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              onPressed: onAddFromGallery,
            ),
            const SizedBox(height: 12),
            AppAddItemButton(
              buttonKey: Key('create-training-${weekday.name}'),
              label: 'Criar treinamento',
              height: 54,
              backgroundColor: const Color(0xFFEBEBEB),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              onPressed: onCreateTraining,
            ),
            const SizedBox(height: 16),
            Text(
              'Treinamento selecionado',
              style: textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nenhum',
              key: Key('empty-training-${weekday.name}'),
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'Treinamento selecionado',
              style: textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            SelectedDayTrainingCard(
              training: training!,
              removeKey: onRemoveTraining != null
                  ? ValueKey('remove-weekday-training-${weekday.name}')
                  : null,
              onRemove: onRemoveTraining,
            ),
          ],
        ],
      ),
    );
  }
}

/// Card interno com resumo do treinamento selecionado (título, duração, lista
/// de exercícios e botão opcional de remoção).
class SelectedDayTrainingCard extends StatelessWidget {
  const SelectedDayTrainingCard({
    required this.training,
    this.removeKey,
    this.onRemove,
    super.key,
  });

  final TrainingPlanGalleryItem training;
  final Key? removeKey;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 16),
      decoration: const BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TrainingMetadataColumn(training: training),
          ),
          if (onRemove != null)
            IconButton(
              key: removeKey,
              onPressed: onRemove,
              tooltip: 'Remover ${training.title}',
              icon: const Icon(
                Icons.delete_rounded,
                color: AppColors.error,
                size: 26,
              ),
            ),
        ],
      ),
    );
  }
}

/// Card interativo com checkbox exibido na listagem da galeria de treinamentos.
class GalleryTrainingSelectableCard extends StatelessWidget {
  const GalleryTrainingSelectableCard({
    required this.training,
    required this.isSelected,
    required this.onToggle,
    this.cardKey,
    super.key,
  });

  final TrainingPlanGalleryItem training;
  final bool isSelected;
  final VoidCallback onToggle;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFDCDCDC),
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: cardKey,
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 18, 16),
          child: Row(
            children: [
              Transform.scale(
                scale: 1.15,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (_) => onToggle(),
                  activeColor: AppColors.seaGreen,
                  checkColor: Colors.white,
                  side: const BorderSide(color: AppColors.text, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _TrainingMetadataColumn(training: training)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrainingMetadataColumn extends StatelessWidget {
  const _TrainingMetadataColumn({required this.training});

  final TrainingPlanGalleryItem training;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.text,
      height: 1.32,
    );
    final valueStyle = textTheme.bodyMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: AppColors.text,
      height: 1.32,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          training.title,
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Duração: ', style: labelStyle),
              TextSpan(text: training.formattedDuration, style: valueStyle),
            ],
          ),
        ),
        const Divider(color: AppColors.grey, height: 18, thickness: 0.8),
        Text('Exercícios selecionados:', style: labelStyle),
        const SizedBox(height: 4),
        if (training.exerciseNames.isEmpty)
          Text('Nenhum exercício registrado', style: valueStyle)
        else
          for (final exerciseName in training.exerciseNames)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('·  ', style: valueStyle),
                  Expanded(child: Text(exerciseName, style: valueStyle)),
                ],
              ),
            ),
      ],
    );
  }
}
