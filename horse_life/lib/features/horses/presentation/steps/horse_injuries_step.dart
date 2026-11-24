// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Reutilização dos componentes padronizados AppAddItemButton e
// AppRemovableItemTile de core/widgets, exibindo data, detalhes em destaque
// e prescrição com ícone Symbols.rheumatology em AppColors.seaGreen.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Histórico de lesões separado do coordenador do cadastro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/models/horse_registration_draft.dart';

class HorseInjuriesStep extends StatelessWidget {
  const HorseInjuriesStep({
    required this.injuries,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final List<HorseInjury> injuries;
  final VoidCallback onAdd;
  final ValueChanged<HorseInjury> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppAddItemButton(
          buttonKey: const Key('horse-add-injury-button'),
          label: 'Adicionar lesão',
          onPressed: onAdd,
        ),
        if (injuries.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (var index = 0; index < injuries.length; index++) ...[
            AppRemovableItemTile(
              key: ValueKey('horse-injury-$index'),
              icon: Symbols.rheumatology,
              iconColor: AppColors.seaGreen,
              removeKey: ValueKey('remove-horse-injury-$index'),
              onRemove: () => onRemove(injuries[index]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatAppDate(injuries[index].date),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    injuries[index].description,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  if (injuries[index].prescription != null &&
                      injuries[index].prescription!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      injuries[index].prescription!.trim(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (index < injuries.length - 1) const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}
