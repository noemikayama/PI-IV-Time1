// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Reutilização dos componentes padronizados AppAddItemButton e
// AppRemovableItemTile de core/widgets com ícones temáticos em AppColors.seaGreen,
// alinhando o layout de limitações e saúde à prototipação.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Listas de limitações e saúde reunidas em componente reutilizável.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

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
    final buttonKey = isLimitation
        ? const Key('horse-add-limitation-button')
        : const Key('horse-add-health-button');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppAddItemButton(
          buttonKey: buttonKey,
          label: label,
          onPressed: onAdd,
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (var index = 0; index < items.length; index++) ...[
            AppRemovableItemTile(
              key: ValueKey('horse-note-$index'),
              icon: isLimitation
                  ? Symbols.do_not_touch
                  : Symbols.health_metrics,
              iconColor: AppColors.seaGreen,
              label: items[index],
              maxLines: null,
              removeKey: ValueKey('remove-horse-note-$index'),
              onRemove: () => onRemove(items[index]),
            ),
            if (index < items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}
