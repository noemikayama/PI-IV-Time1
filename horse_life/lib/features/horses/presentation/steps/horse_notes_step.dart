// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Listas de limitações e saúde reunidas em componente reutilizável.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:horse_life/app/theme/app_colors.dart';

import '../widgets/horse_add_button.dart';
import '../widgets/horse_registration_entry_tile.dart';
import '../widgets/horse_registration_pictogram.dart';

enum HorseNotesType { limitations, health }

class HorseNotesStep extends StatelessWidget {
  const HorseNotesStep({
    required this.type,
    required this.items,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final HorseNotesType type;
  final List<String> items;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final isLimitation = type == HorseNotesType.limitations;
    final label = isLimitation ? 'Adicionar limitação' : 'Adicionar observação';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HorseAddButton(label: label, onPressed: onAdd),
        const SizedBox(height: 14),
        for (final item in List<String>.of(items))
          HorseRegistrationEntryTile(
            item,
            isLimitation
                ? const Icon(Symbols.do_not_touch, size: 24, color: AppColors.blueSpruce)
                : const HorseRegistrationPictogram(kind: HorsePictogram.health),
            () => onRemove(item),
          ),
      ],
    );
  }
}
