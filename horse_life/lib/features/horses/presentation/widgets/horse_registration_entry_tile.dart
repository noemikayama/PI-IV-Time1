// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Linha reutilizável para imagens, limitações, saúde e lesões.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

class HorseRegistrationEntryTile extends StatelessWidget {
  const HorseRegistrationEntryTile(this.label, this.leading, this.onDelete, {super.key});

  final String label;
  final Widget leading;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.alabasterGray.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      child: Row(children: [
        SizedBox(width: 24, height: 24, child: Center(child: leading)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, softWrap: true)),
        IconButton(onPressed: onDelete, tooltip: 'Remover',
          icon: const Icon(Icons.delete, color: AppColors.error, size: 22)),
      ]),
    ),
  );
}
