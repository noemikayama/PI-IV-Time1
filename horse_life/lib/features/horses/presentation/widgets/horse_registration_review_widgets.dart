// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Alinhamento visual dos campos de revisão à prototipação, com estilo
// InputDecorator com linha verde, texto headlineSmall e ícone de edição/calendário.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Campos de revisão com edição sem duplicar layout na screen.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

class HorseRegistrationReviewField extends StatelessWidget {
  const HorseRegistrationReviewField({
    required this.label,
    required this.value,
    required this.step,
    required this.onEdit,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final int step;
  final ValueChanged<int> onEdit;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = value.trim();
    final isEmpty = display.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        key: ValueKey('review-field-$label'),
        onTap: () => onEdit(step),
        child: InputDecorator(
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.only(top: 14, bottom: 12),
            suffixIcon: Icon(
              icon ?? Icons.edit_rounded,
              color: AppColors.seaGreen,
              size: 26,
            ),
          ),
          child: Text(
            isEmpty ? label : display,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 20,
              color: isEmpty ? AppColors.grey : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class HorseRegistrationReviewSectionTitle extends StatelessWidget {
  const HorseRegistrationReviewSectionTitle(
    this.title,
    this.step, {
    required this.onEdit,
    super.key,
  });

  final String title;
  final int step;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: () => onEdit(step),
          tooltip: 'Editar $title',
          icon: const Icon(Icons.edit_rounded, size: 24, color: AppColors.seaGreen),
        ),
      ],
    ),
  );
}
