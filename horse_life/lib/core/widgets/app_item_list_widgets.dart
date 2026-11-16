// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Inclusão do parâmetro opcional child no AppRemovableItemTile para
// permitir conteúdo personalizado com múltiplas linhas (ex.: cards de lesões).
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos widgets globais de listas de itens em core/widgets,
// generalizando botão de adição, card de item removível e seção de revisão.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Botão cinza arredondado padronizado para inclusão de itens em fluxos de formulários.
class AppAddItemButton extends StatelessWidget {
  const AppAddItemButton({
    required this.buttonKey,
    required this.label,
    required this.onPressed,
    this.semanticsLabel,
    this.isLoading = false,
    this.icon = Icons.add_rounded,
    this.height = 64,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.backgroundColor = const Color(0xFFE9E9E9),
    super.key,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;
  final String? semanticsLabel;
  final bool isLoading;
  final IconData icon;
  final double height;
  final BorderRadius borderRadius;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: Material(
        color: backgroundColor,
        borderRadius: borderRadius,
        child: InkWell(
          key: buttonKey,
          onTap: isLoading ? null : onPressed,
          borderRadius: borderRadius,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isLoading)
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    Icon(
                      icon,
                      color: AppColors.text,
                      size: 32,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card reutilizável com ícone temático, rótulo descritivo e botão de remoção.
class AppRemovableItemTile extends StatelessWidget {
  const AppRemovableItemTile({
    required this.icon,
    required this.removeKey,
    required this.onRemove,
    this.label,
    this.child,
    this.minHeight = 64,
    this.maxLines = 1,
    this.iconColor = AppColors.blueSpruce,
    this.deleteIconColor = AppColors.error,
    this.backgroundColor = const Color(0xFFE9E9E9),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    super.key,
  }) : assert(
         label != null || child != null,
         'Either label or child must be provided to AppRemovableItemTile',
       );

  final IconData icon;
  final String? label;
  final Widget? child;
  final Key removeKey;
  final VoidCallback? onRemove;
  final double minHeight;
  final int? maxLines;
  final Color iconColor;
  final Color deleteIconColor;
  final Color backgroundColor;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: child ??
                Text(
                  label!,
                  maxLines: maxLines,
                  overflow: maxLines != null ? TextOverflow.ellipsis : null,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontSize: 19, height: 1.2),
                ),
          ),
          IconButton(
            key: removeKey,
            onPressed: onRemove,
            tooltip: label != null ? 'Remover $label' : 'Remover item',
            icon: Icon(
              Icons.delete_rounded,
              color: deleteIconColor,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

/// Agrupa visualmente uma seção de revisão com título, estado vazio e lista de itens.
class AppReviewSection extends StatelessWidget {
  const AppReviewSection({
    required this.title,
    required this.emptyMessage,
    required this.children,
    this.titleStyle,
    this.spacing = 12,
    super.key,
  });

  final String title;
  final String emptyMessage;
  final List<Widget> children;
  final TextStyle? titleStyle;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: titleStyle ??
              Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        if (children.isEmpty)
          Text(
            emptyMessage,
            key: ValueKey('empty-$title'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
          )
        else
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1) SizedBox(height: spacing),
          ],
      ],
    );
  }
}
