// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Campos de revisão com edição sem duplicar layout na screen.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

class HorseRegistrationReviewField extends StatelessWidget {
  const HorseRegistrationReviewField(
    this.label, this.value, this.step, {required this.onEdit, super.key});

  final String label;
  final String value;
  final int step;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onEdit(step),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          Text(value.isEmpty ? 'Não informado' : value),
          const SizedBox(height: 5),
          const Divider(color: AppColors.seaGreen, height: 1),
        ])),
        const SizedBox(width: 12),
        const Icon(Icons.edit, color: AppColors.seaGreen),
      ]),
    ),
  );
}

class HorseRegistrationReviewSectionTitle extends StatelessWidget {
  const HorseRegistrationReviewSectionTitle(
    this.title, this.step, {required this.onEdit, super.key});

  final String title;
  final int step;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Row(children: [
      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
      IconButton(onPressed: () => onEdit(step),
        tooltip: 'Editar $title',
        icon: const Icon(Icons.edit, size: 20, color: AppColors.seaGreen)),
    ]),
  );
}
