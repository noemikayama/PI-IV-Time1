// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Reutilização dos componentes padronizados AppAddItemButton e
// AppRemovableItemTile de core/widgets, com rolagem e indicador de scrollbar
// para 3 ou mais mídias, alinhado à prototipação e ao fluxo de exercícios.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Lista de imagens e ação de seleção isoladas da tela principal.
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

class HorseImagesStep extends StatefulWidget {
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
  State<HorseImagesStep> createState() => _HorseImagesStepState();
}

class _HorseImagesStepState extends State<HorseImagesStep> {
  static const _itemHeight = 64.0;
  static const _itemSpacing = 12.0;
  static const _maximumVisibleItems = 3;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildImageList(BuildContext context) {
    final visibleCount = math.min(widget.images.length, _maximumVisibleItems);
    final listHeight =
        visibleCount * _itemHeight + (visibleCount - 1) * _itemSpacing;

    return SizedBox(
      key: const Key('horse-images-list'),
      height: listHeight,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: widget.images.length >= _maximumVisibleItems,
        child: ListView.separated(
          controller: _scrollController,
          primary: false,
          padding: EdgeInsets.only(
            right: widget.images.length >= _maximumVisibleItems ? 14 : 0,
          ),
          itemCount: widget.images.length,
          separatorBuilder: (_, _) => const SizedBox(height: _itemSpacing),
          itemBuilder: (context, index) {
            final file = widget.images[index];
            return AppRemovableItemTile(
              key: ValueKey('horse-image-item-$index'),
              icon: Symbols.image,
              iconColor: AppColors.seaGreen,
              label: file.name,
              removeKey: ValueKey('remove-horse-image-${file.name}'),
              onRemove: () => widget.onRemove(file),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppAddItemButton(
          buttonKey: const Key('horse-add-image-button'),
          label: 'Adicionar imagem',
          semanticsLabel: 'Adicionar imagens do cavalo',
          onPressed: widget.onAdd,
        ),
        if (widget.images.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildImageList(context),
        ],
      ],
    );
  }
}
