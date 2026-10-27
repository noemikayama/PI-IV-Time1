// RESPONSÁVEL PELA ATUALIZAÇÃO: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão e padronização dos componentes e dados simulados da Home do Responsável, preservando a integração existente.
// -----------------------------------------------------------------------------
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Itens visuais migrados para HomeListTile sem alterar lógica de
// rolagem, mensagens, callbacks nem contratos da lista do Guardian.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'guardian_section_card.dart';
import 'home_list_tile.dart';
import 'guardian_empty_state.dart';

/// Renderiza coleções de cavalos ou profissionais, incluindo estado vazio e limite de altura.
class GuardianListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;
  final bool useHorseAsset;
  final bool showArrow;
  final int? maxVisibleItems;
  final VoidCallback? onShowAll;
  final void Function(int index)? onItemTap;
  final VoidCallback? onRegisterHorse;

  const GuardianListCard({
    super.key,
    required this.title,
    required this.items,
    required this.icon,
    this.useHorseAsset = false,
    this.showArrow = false,
    this.maxVisibleItems,
    this.onShowAll,
    this.onItemTap,
    this.onRegisterHorse,
  });

  @override
  Widget build(BuildContext context) {
    final needsScroll = maxVisibleItems != null && items.length > maxVisibleItems!;
    // A lista pode rolar internamente quando ultrapassa o limite de itens visíveis.
    final itemList = ListView.separated(
      itemCount: items.length,
      shrinkWrap: !needsScroll,
      physics: needsScroll ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => HomeListTile(
        label: items[index],
        icon: icon,
        useHorseAsset: useHorseAsset,
        showArrow: showArrow,
        onTap: onItemTap == null ? null : () => onItemTap!(index),
      ),
    );

    return GuardianSectionCard(
      title: title,
      onShowAll: onShowAll,
      child: items.isEmpty
          ? GuardianEmptyState(
              icon: Icons.block_outlined,
              title: useHorseAsset ? 'Nenhum animal cadastrado' : 'Nenhum profissional vinculado',
              description: useHorseAsset
                  ? 'Cadastre um cavalo agora mesmo e comece a desfrutar do HorseLife!'
                  : 'Ao vincular um treinador ao seu animal, você se vincula a ele automaticamente.',
              actionLabel: useHorseAsset ? 'Cadastrar animal' : null,
              onAction: onRegisterHorse,
            )
          : needsScroll
              ? SizedBox(
                  height: (maxVisibleItems! * 70.0) + ((maxVisibleItems! - 1) * 12.0),
                  child: Scrollbar(thumbVisibility: true, child: itemList),
                )
              : itemList,
    );
  }
}

