// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Lista de imagens e ação de seleção isoladas da tela principal.
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:horse_life/app/theme/app_colors.dart';

import '../widgets/horse_add_button.dart';
import '../widgets/horse_registration_entry_tile.dart';

class HorseImagesStep extends StatelessWidget {
  const HorseImagesStep({
    required this.images,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final List<XFile> images;
  final VoidCallback onAdd;
  final ValueChanged<XFile> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HorseAddButton(label: 'Adicionar imagem', onPressed: onAdd),
      const SizedBox(height: 14),
      for (final file in List<XFile>.of(images))
        HorseRegistrationEntryTile(
          file.name,
          const Icon(Symbols.image, size: 24, color: AppColors.blueSpruce),
          () => onRemove(file),
        ),
      const SizedBox(height: 10),
      Text(
        'Opcional • JPG ou PNG • até 5 MB cada • máximo de 10 imagens',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}
