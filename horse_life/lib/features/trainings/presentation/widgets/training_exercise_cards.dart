// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos cards de exibição de exercícios selecionados e de
// seleção múltipla na galeria do formulário de cadastro de treinamentos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

import '../../data/models/training_exercise_item.dart';

/// Card exibido na lista de exercícios selecionados da etapa de seleção,
/// apresentando nome, tempo estimado, tipo, cavalo vinculado (quando
/// específico) e botão de exclusão.
class SelectedTrainingExerciseCard extends StatelessWidget {
  const SelectedTrainingExerciseCard({
    required this.exercise,
    required this.removeKey,
    required this.onRemove,
    super.key,
  });

  final TrainingExerciseItem exercise;
  final Key removeKey;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 10, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFE9E9E9),
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _ExerciseMetadataColumn(
              exercise: exercise,
              titleStyle: textTheme.headlineSmall?.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              labelStyle: textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                height: 1.35,
              ),
              valueStyle: textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.text,
                height: 1.35,
              ),
            ),
          ),
          IconButton(
            key: removeKey,
            onPressed: onRemove,
            tooltip: 'Remover ${exercise.name}',
            icon: const Icon(
              Icons.delete_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

/// Card interativo com checkbox utilizado na listagem do bottom sheet de
/// galeria de exercícios.
class GalleryExerciseSelectableCard extends StatelessWidget {
  const GalleryExerciseSelectableCard({
    required this.exercise,
    required this.isSelected,
    required this.onToggle,
    this.cardKey,
    super.key,
  });

  final TrainingExerciseItem exercise;
  final bool isSelected;
  final VoidCallback onToggle;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: const Color(0xFFDCDCDC),
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: cardKey,
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
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
              Expanded(
                child: _ExerciseMetadataColumn(
                  exercise: exercise,
                  titleStyle: textTheme.headlineSmall?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                  labelStyle: textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                    height: 1.32,
                  ),
                  valueStyle: textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.text,
                    height: 1.32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseMetadataColumn extends StatelessWidget {
  const _ExerciseMetadataColumn({
    required this.exercise,
    required this.titleStyle,
    required this.labelStyle,
    required this.valueStyle,
  });

  final TrainingExerciseItem exercise;
  final TextStyle? titleStyle;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(exercise.name, style: titleStyle),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Tempo estimado: ', style: labelStyle),
              TextSpan(text: exercise.formattedDuration, style: valueStyle),
            ],
          ),
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Tipo de exercício: ', style: labelStyle),
              TextSpan(text: exercise.formattedType, style: valueStyle),
            ],
          ),
        ),
        if (exercise.isSpecific && exercise.horse != null)
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Cavalo vinculado: ', style: labelStyle),
                TextSpan(text: exercise.horse!.name, style: valueStyle),
              ],
            ),
          ),
      ],
    );
  }
}
