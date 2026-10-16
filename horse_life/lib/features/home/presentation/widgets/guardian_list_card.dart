import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import 'guardian_section_card.dart';
import 'horse_asset_icon.dart';
import 'guardian_empty_state.dart';

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
    final itemList = ListView.separated(
      itemCount: items.length,
      shrinkWrap: !needsScroll,
      physics: needsScroll ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ItemTile(
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

class _ItemTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool useHorseAsset;
  final bool showArrow;
  final VoidCallback? onTap;
  const _ItemTile({required this.label, required this.icon, required this.useHorseAsset,
    required this.showArrow, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.whiteSmoke,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        height: 70,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(children: [
            useHorseAsset
                ? const HorseAssetIcon(size: 28)
                : Icon(icon, color: AppColors.prussianBlue, size: 28),
            const SizedBox(width: 14),
            Expanded(child: Text(label,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge)),
            if (showArrow) const Icon(Icons.chevron_right, color: AppColors.prussianBlue),
          ]),
        ),
      ),
    ),
  );
}
