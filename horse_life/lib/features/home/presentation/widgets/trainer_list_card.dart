// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Criação de listagem reutilizável de cavalos e clientes,
// com rolagem quando necessário e mensagens específicas para listas vazias.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão de integração e compatibilidade com a arquitetura
// Repository/Mapper/Service, sem alterar a composição visual aprovada.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Linhas renderizadas por HomeListTile; mantidos tipos,
// callbacks, scroll e estados vazios próprios do Professional.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'home_empty_state.dart';
import 'home_section_card.dart';
import 'home_list_tile.dart';

/// O tipo genérico preserva os modelos próprios de cavalos e clientes.
class TrainerListCard<T> extends StatelessWidget {
  const TrainerListCard({
    super.key,
    required this.title,
    required this.items,
    required this.itemName,
    required this.emptyTitle,
    required this.emptyDescription,
    this.isHorseList = false,
    this.maxVisibleItems = 2,
    this.onShowAll,
    this.onItemTap,
  });

  final String title;
  final List<T> items;
  final String Function(T) itemName;
  final String emptyTitle;
  final String emptyDescription;
  final bool isHorseList;
  final int maxVisibleItems;
  final VoidCallback? onShowAll;
  final ValueChanged<T>? onItemTap;

  @override
  Widget build(BuildContext context) {
    final shouldScroll = items.length > maxVisibleItems;

    return HomeSectionCard(
      title: title,
      onShowAll: onShowAll,
      child: items.isEmpty
          ? HomeEmptyState(
              icon: Icons.block_outlined,
              title: emptyTitle,
              description: emptyDescription,
            )
          : shouldScroll
              ? SizedBox(
                  height: maxVisibleItems * 56.0 + (maxVisibleItems - 1) * 8.0,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.separated(
                      padding: const EdgeInsets.only(right: 6),
                      physics: const ClampingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) => HomeListTile(
                        label: itemName(items[index]),
                        useHorseAsset: isHorseList,
                        showArrow: isHorseList,
                        density: HomeListTileDensity.compact,
                        onTap: onItemTap == null
                            ? null
                            : () => onItemTap!(items[index]),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      HomeListTile(
                        label: itemName(items[i]),
                        useHorseAsset: isHorseList,
                        showArrow: isHorseList,
                        density: HomeListTileDensity.compact,
                        onTap: onItemTap == null
                            ? null
                            : () => onItemTap!(items[i]),
                      ),
                    ],
                  ],
                ),
    );
  }
}

